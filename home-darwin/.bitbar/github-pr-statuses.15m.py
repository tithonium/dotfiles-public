#!/usr/bin/env python
# -*- coding: utf-8 -*-

# <bitbar.title>Github review requests</bitbar.title>
# <bitbar.desc>Shows a list of PRs that need to be reviewed</bitbar.desc>
# <bitbar.version>v0.1</bitbar.version>
# <bitbar.author>Adam Bogdał</bitbar.author>
# <bitbar.author.github>bogdal</bitbar.author.github>
# <bitbar.image>https://github-bogdal.s3.amazonaws.com/bitbar-plugins/review-requests.png</bitbar.image>
# <bitbar.dependencies>python</bitbar.dependencies>

# ----------------------
# ---  BEGIN CONFIG  ---
# ----------------------

# https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
ACCESS_TOKEN = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

GITHUB_LOGIN = 'tithonium'

# (optional) PRs with this label (e.g 'in progress') will be grayed out on the list
WIP_LABEL = 'WIP'

# (optional) Filter the PRs by an organization, labels, etc. E.g 'org:YourOrg -label:dropped'
FILTERS = 'author:%s' % GITHUB_LOGIN

# --------------------
# ---  END CONFIG  ---
# --------------------

import datetime
import json
import os
import sys
import re
try:
    # For Python 3.x
    from urllib.request import Request, urlopen
except ImportError:
    # For Python 2.x
    from urllib2 import Request, urlopen


DARK_MODE = os.environ.get('BitBarDarkMode')

query = '''{
  search(query: "%(search_query)s", type: ISSUE, first: 100) {
    issueCount
    edges {
      node {
        ... on PullRequest {
          repository {
            nameWithOwner
          }
          author {
            login
          }
          createdAt
          number
          url
          title
          baseRefName
          headRefName
          reviews(last: 100) {
            totalCount
            nodes {
              updatedAt
              state
              author {
                login
              }
            }
          }
          labels(first:100) {
            nodes {
              name
            }
          }
        }
      }
    }
  }
}'''


colors = {
    'inactive': '#b4b4b4',
    'title': '#cccccc' if DARK_MODE else '#000000',
    'master': '#ffffff',
    'release': '#ffaaaa',
    'approved': '#44ff44',
    # 'subtitle': '#687079'
    'subtitle': '#cc8888'
    }


def execute_query(query):
    headers = {
        'Authorization': 'bearer ' + ACCESS_TOKEN,
        'Content-Type': 'application/json'}
    data = json.dumps({'query': query}).encode('utf-8')
    req = Request(
        'https://api.github.com/graphql', data=data, headers=headers)
    body = urlopen(req).read()
    return json.loads(body)


def search_pull_requests(login, filters=''):
    search_query = 'type:pr state:open %(filters)s' % {
        'login': login, 'filters': filters}
    response = execute_query(query % {'search_query': search_query})
    response = response['data']['search']
    for pr in [r['node'] for r in response['edges']]:
      approval_count = 0
      for appr in pr['reviews']['nodes']:
          if appr['state'] == 'APPROVED':
              approval_count = approval_count + 1
      pr['approval_count'] = approval_count
      if approval_count >= 2 or (approval_count >= 1 and not (pr['baseRefName'] == 'master' or pr['baseRefName'] == 'release')):
          pr['approved'] = True
      else:
          pr['approved'] = False
    return response


def parse_date(text):
    date_obj = datetime.datetime.strptime(text, '%Y-%m-%dT%H:%M:%SZ')
    return date_obj.strftime('%B %d, %Y')


def print_line(text, **kwargs):
    params = ' '.join(['%s=%s' % (key, value) for key, value in kwargs.items()])
    print('%s | %s' % (text, params) if kwargs.items() else text)


def open_all(response, prefix):
    if prefix == 'approved':
      for pr in [r['node'] for r in response['edges']]:
        if pr['approved']:
          os.system("open " + pr['url'])
    elif prefix == 'unapproved':
      for pr in [r['node'] for r in response['edges']]:
        if not pr['approved']:
          os.system("open " + pr['url'])
    elif prefix:
      regex = re.compile(prefix + '-\d+', re.I)
      for pr in [r['node'] for r in response['edges']]:
        if regex.search(pr['title']):
          os.system("open " + pr['url'])
    else:
      for pr in [r['node'] for r in response['edges']]:
        os.system("open " + pr['url'])

def display(response):
    print_line('MyPRs:%s' % response['issueCount'])
    print_line('---')

    unapproved_prs = 0
    approved_prs = 0
    groups = {}
    for pr in [r['node'] for r in response['edges']]:
        labels = [l['name'] for l in pr['labels']['nodes']]
        title = '%s - %s' % (pr['repository']['nameWithOwner'], pr['title'])
        title_color = colors.get('inactive' if WIP_LABEL in labels else 'title')
        if pr['baseRefName'] == 'master':
            title_color = colors.get('master')
        elif pr['baseRefName'] == 'release':
            title_color = colors.get('release')

        # fucking unicode support problems
        # if pr['approval_count'] >= 2:
        #     title = u'\u2705' + ' ' + title.decode('utf-8')

        subtitle = '#%s  %s <- %s; %d approval%s, opened on %s' % (pr['number'], pr['baseRefName'], pr['headRefName'],
                                                                   pr['approval_count'], 's' if pr['approval_count'] != 1 else '', parse_date(pr['createdAt']))
        subtitle_color = colors.get('inactive' if WIP_LABEL in labels else 'subtitle')
        if pr['approved']:
            approved_prs = approved_prs + 1
            title_color = colors.get('approved')
            subtitle_color = colors.get('approved')
        else:
            unapproved_prs = unapproved_prs + 1

        print_line(title, size=16, color=title_color, href=pr['url'])
        print_line(subtitle, size=12, color=subtitle_color)
        print_line('---')

        for prefix in re.findall('([a-zA-Z]+)-\d+', pr['title']):
          if prefix not in groups:
            groups[prefix] = []
          groups[prefix].append(pr['url'])

    print_line('Open All | bash=' + sys.argv[0] + " param1=--open terminal=false")
    print_line('Open List | href=https://github.com/pulls?q=is%3Aopen+is%3Apr+author%3A' + GITHUB_LOGIN + '+archived%3Afalse+user%3AAPX')
    for prefix in sorted(groups.keys()):
      print("Open All " + prefix + " | bash=" + sys.argv[0] + " param1=--open param2=" + prefix + " terminal=false")
    if approved_prs > 0:
      print_line('Open Approved | bash=' + sys.argv[0] + " param1=--open param2=approved terminal=false")
    if unapproved_prs > 0:
      print_line('Open Unapproved | bash=' + sys.argv[0] + " param1=--open param2=unapproved terminal=false")

    print_line('Refresh... | refresh=true')

if __name__ == '__main__':
    if not all([ACCESS_TOKEN, GITHUB_LOGIN]):
        print_line('⚠ Github review requests', color='red')
        print_line('---')
        print_line('ACCESS_TOKEN and GITHUB_LOGIN cannot be empty')
        sys.exit(0)

    response = search_pull_requests(GITHUB_LOGIN, FILTERS)

    if len(sys.argv) > 1 and sys.argv[1] == "--open":
        if len(sys.argv) > 2:
           open_all(response, sys.argv[2])
        else:
           open_all(response, '')

    else:
        display(response)
