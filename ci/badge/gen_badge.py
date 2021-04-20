#!/usr/bin/env python3

##
# Copyright (C) 2019 Samsung Electronics
# License: Apache-2.0
#
# @file gen_github_badge_svg.py
# @brief A tool for generating a github badge image in svg format
# @author Wook Song <wook16.song@samsung.com>
# @note
# usage :  ../badge/gen_badge.py {badge-name} {gcov-index-file} {output.svg}
#    $ cd ci
#    $ ../badge/gen_badge.py codecoverage ../gcov_html/index.html ../badge/codecoverage.svg
#
import sys
import os
# https://pypi.org/project/BeautifulSoup/
from bs4 import BeautifulSoup
# https://pypi.org/project/requests/
import requests
# https://pypi.org/project/svgwrite/
import svgwrite

##
# @brief Get a string representing the whole html file of a given url
# @param[in] url A valid url-string indicating a specific html file
def get_html(url):
    """get_html(url) -> str"""
    _html = ''
    resp = requests.get(url)
    if resp.status_code == 200:
        _html = resp.text
    return _html

##
# @brief Get a gradient colorcode from green to red of given value (scaled)
# @param[in] val A value to be conveted to a gradient colorcode (i.e., #FFFFFF)
# @param[in] scale A limit for the val, 0 <= val <= scale
def get_code_g_y_r(val, scale):
    """get_code_g_y_r(val, scale) -> str"""
    if val <= 50:
        red = 255
        green = val * (255 / (float(scale) / 2))
    else:
        green = 255 * val / scale
        red = 255 - (val - 50) * (255 / (float(scale) / 2))

    rgb = (int(red), int(green), int(0))

    return '#%02x%02x%02x' % rgb

##
# @brief Generate a github badge svg file representing code coverage
# @param[in] html A concatenated string of the whole contents in index.html that is the result of LCOV
# @param[in] path A file path to save the svg file
def gen_coverage_badge(html, path):
    str_coverage = 'coverage'

    #parse LCOV html
    soup = BeautifulSoup(html, 'html.parser')
    line_hits, lines, func_hits, funcs = \
        soup.find('table').find_all('td', {'class': 'headerCovTableEntry'})
    line_hits = float(line_hits.text)
    lines = float(lines.text)
    func_hits = float(func_hits.text)
    funcs = float(funcs.text)
    line_coverage = line_hits / lines
    rgb_code = get_code_g_y_r(line_coverage * 100, 100)

    dwg = svgwrite.Drawing(path, size=(113.3, 20))
    dwg.viewbox(width=1133, height=200)

    vert_grad = svgwrite.gradients.LinearGradient(None, end=(0, 1), id="vert_lin_grad")
    vert_grad.add_stop_color(offset='0%', color='#FFF', opacity=.1)
    vert_grad.add_stop_color(offset='100%', opacity=.1)
    dwg.defs.add(vert_grad)

    mask = dwg.mask(id="grad_mask")
    mask.add(dwg.rect((0, 0), (1133, 200), rx=30, fill="#FFF"))
    dwg.defs.add(mask)

    grp_rects = dwg.g(id='grp_rects', mask="url(#grad_mask)")
    grp_rects.add(dwg.rect((0, 0), (603, 200), fill="#555"))
    grp_rects.add(dwg.rect((603, 0), (703, 200), fill=rgb_code))
    grp_rects.add(dwg.rect((0, 0), (1133, 200), fill="url(#vert_lin_grad)"))
    dwg.add(grp_rects)

    if line_coverage == 0:
        text_margin = 25
    elif line_coverage == 1:
        text_margin = -25
    else:
        text_margin = 0

    style = 'text-anchor:start;font-family:Verdana,DejaVu Sans,sans-serif;font-size:110px'
    grp_texts = dwg.g(id='grp_texts', fill='#fff', style=style)
    grp_texts.add(dwg.text(str_coverage, (60, 148), textLength='503', fill='#000', opacity='0.25'))
    grp_texts.add(dwg.text(str_coverage, (50, 138), textLength='503'))
    grp_texts.add(dwg.text(format(line_coverage, "2.1%"), (703 + text_margin, 148),\
        textLength='330', fill='#000', opacity='0.25'))
    grp_texts.add(dwg.text(format(line_coverage, "2.1%"), (693 + text_margin, 138),\
        textLength='330'))
    dwg.add(grp_texts)
    dwg.save(path)

if __name__ == '__main__':
    # argv[1]: [badgetype] a string indicating the type of badge, 'codecoverage'
    # argv[2]: [url/file] a path or url of LCOV html to get information for badge generation
    # argv[3]: [file] a file path to save the generated svg file
    if len(sys.argv) < 4:
        exit(1)

    badgetype = 'unknown'
    for each_badge_type in ['codecoverage']:
        if sys.argv[1].lower() == each_badge_type:
            badgetype = sys.argv[1].lower()

    if badgetype == 'unknown':
        exit(1)

    str_html = ''
    if os.path.isfile(sys.argv[2]):
        with open(sys.argv[2], 'r') as f:
            str_html = f.read()
            if not BeautifulSoup(str_html, "html.parser").find():
                exit(1)
    elif sys.argv[2].startswith('http'):
        str_html = get_html(sys.argv[2])
        if str_html == '':
            exit(1)
    else:
        exit(1)

    path_out_svg=''
    if not os.access(os.path.dirname(sys.argv[3]) or os.getcwd(), os.W_OK):
        exit(1)
    else:
        path_out_svg = os.path.abspath(sys.argv[3])
        if os.path.isdir(path_out_svg) or os.path.islink(path_out_svg):
            exit(1)

    if badgetype == 'codecoverage':
        gen_coverage_badge(str_html, path_out_svg)

