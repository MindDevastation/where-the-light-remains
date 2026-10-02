#!/usr/bin/env python3
"""Render the bounded kit contract and check its geometric compatibility.

Standard library only. This checks design arithmetic, not meshes or Godot physics.
"""
import argparse
import html
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def render(contract, output):
    modules = {m['id']: m for m in contract['modules']}
    sample = contract['sample']
    grid = sample['floor_grid']
    xmin = grid['first_center'][0] - 0.5
    xmax = xmin + grid['count_x']
    zmin = grid['first_center'][2] - 0.5
    zmax = zmin + grid['count_z']
    piers = sample['piers']
    for x, y, z in piers:
        assert xmin <= x - 0.3 and xmax >= x + 0.3, 'Unsupported outer pier'
        assert zmin <= z - 0.3 and zmax >= z + 0.3
    walls = sample['facade']
    for first, second in zip(walls, walls[1:]):
        end = first['position'][0] + modules[first['module']]['anchors']['right'][0]
        start = second['position'][0] + modules[second['module']]['anchors']['left'][0]
        assert abs(end - start) <= contract['placement']['snap_tolerance_m']
    replacement = sample['replacement_test']['with']
    before = walls[sample['replacement_test']['replace_facade_index']]
    expected = (before['position'][0] + modules[before['module']]['bounds_min'][0], before['position'][0] + modules[before['module']]['bounds_max'][0])
    intervals = [(p['position'][0] + modules[p['module']]['bounds_min'][0], p['position'][0] + modules[p['module']]['bounds_max'][0]) for p in replacement]
    assert intervals[0][0] == expected[0] and intervals[-1][1] == expected[1]
    assert intervals[0][1] == intervals[1][0]
    # Transform the actual connector vectors, including the corner's 90-degree wall.
    def anchor(item, name, extra_yaw=0):
        v = modules[item['module']]['anchors'][name]
        t = math.radians(item['yaw'])
        x = item['position'][0] + v[0] * math.cos(t) + v[2] * math.sin(t)
        z = item['position'][2] - v[0] * math.sin(t) + v[2] * math.cos(t)
        q = math.radians(extra_yaw)
        return (x * math.cos(q) + z * math.sin(q), -x * math.sin(q) + z * math.cos(q))
    for yaw in contract['placement']['yaw_degrees']:
        for first, second in zip(walls, walls[1:]):
            assert math.dist(anchor(first, 'right', yaw), anchor(second, 'left', yaw)) < 1e-9
        corner = sample['corner_test']
        assert math.dist(anchor(corner[0], 'right', yaw), anchor(corner[1], 'right', yaw)) < 1e-9
    opening = modules['arch_4m']['opening']
    a = opening['width_m'] / 2
    h = opening['apex_y_m'] - opening['spring_y_m']
    c = (h*h-a*a)/(2*a)
    radius = a+c
    angle = math.acos(-c/radius)
    n = opening['segments_per_half']
    left = [(c+radius*math.cos(math.pi+(angle-math.pi)*i/n), opening['spring_y_m']+radius*math.sin(math.pi+(angle-math.pi)*i/n)) for i in range(n+1)]
    profile = left + [(-x,y) for x,y in reversed(left[:-1])]
    sagitta = radius * (1-math.cos((math.pi-angle)/(2*n)))
    probe = sample['walk_probe']
    side_margin = min(a-abs(x)-probe['radius_m'] for x in probe['center_x_lanes'])
    head_margin = opening['spring_y_m']-probe['height_m']-probe['feet_y']
    assert side_margin + 1e-9 >= probe['minimum_side_clearance_m']
    assert head_margin + 1e-9 >= probe['minimum_head_clearance_m']
    assert zmin < probe['start_z'] < probe['end_z'] < zmax
    floors = grid['count_x'] * grid['count_z']
    triangles = floors * modules['floor_1m']['triangle_ceiling'] + sum(modules[p['module']]['triangle_ceiling'] for p in walls) + len(piers)*modules['pier_4m']['triangle_ceiling']
    swapped = triangles-modules[before['module']]['triangle_ceiling']+sum(modules[p['module']]['triangle_ceiling'] for p in replacement)
    surfaces = floors + sum(len(modules[p['module']]['materials']) for p in walls) + len(piers)*len(modules['pier_4m']['materials'])
    print(f'CONTRACT_ANALYTICAL PASS: {floors} floor cells, supported piers, straight/replacement/corner anchors at four yaws')
    print(f'PASSAGE_ARITHMETIC PASS: side margin {side_margin:.3f} m; head margin {head_margin:.3f} m; curve chord deviation <= {sagitta:.6f} m')
    print(f'AUTHORING_CEILING (not measured): {triangles} triangles; replacement {swapped}; {surfaces} surfaces before rendering passes')
    print('PENDING: actual meshes, import, physics traversal, visual acceptance, LFS payloads and representative hardware profiling')
    svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="1280" height="1040" viewBox="0 0 1280 1040">', '<rect width="1280" height="1040" fill="#f6f4ef"/>', '<defs><marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="#495769"/></marker></defs>']
    def text(x,y,s,size=18,color='#263544',anchor='start'):
        svg.append(f'<text x="{x}" y="{y}" font-family="DejaVu Sans,sans-serif" font-size="{size}" fill="{color}" text-anchor="{anchor}">{html.escape(s)}</text>')
    def line(x1,y1,x2,y2,color='#495769',width=1,dash='',arrows=False):
        attrs = ' marker-start="url(#arrow)" marker-end="url(#arrow)"' if arrows else ''
        svg.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="{width}" stroke-dasharray="{dash}"{attrs}/>')
    def rect(x,y,w,h,fill,stroke='#59616a'):
        svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" stroke="{stroke}"/>')
    text(64,53,'АРХИВ · КОНТРАКТ МОДУЛЬНОГО ОБРАЗЦА v1',30)
    text(64,87,'Размерная схема. Меши, физика и художественная приемка еще не выполнены.',17,'#666b72')
    text(64,142,'ФАСАД · ширина конструктивного ряда 12 м',20)
    front_scale=65
    fx=lambda x:640+x*front_scale
    fy=lambda y:470-y*65
    for p in walls:
        m=modules[p['module']]; x=p['position'][0]
        if p['module']!='arch_4m':
            rect(fx(x+m['bounds_min'][0]),fy(4),(m['bounds_max'][0]-m['bounds_min'][0])*front_scale,260,'#d9d1c3')
        else:
            points=[(-a,0)]+profile+[(a,0)]
            outer=f'M {fx(-2)} {fy(0)} L {fx(2)} {fy(0)} L {fx(2)} {fy(4)} L {fx(-2)} {fy(4)} Z '
            hole='M '+' L '.join(f'{fx(px):.3f} {fy(py):.3f}' for px,py in points)+' Z'
            svg.append(f'<path d="{outer+hole}" fill="#d9d1c3" fill-rule="evenodd" stroke="#59616a"/>')
            svg.append('<polyline points="'+' '.join(f'{fx(px):.3f},{fy(py):.3f}' for px,py in profile)+'" fill="none" stroke="#a07a3b" stroke-width="4"/>')
    for x,_,_ in piers:
        rect(fx(x-.23),fy(4),.46*front_scale,4*65,'#c8beac')
        rect(fx(x-.3),fy(4.12),.6*front_scale,.12*65,'#a78e62')
        rect(fx(x-.3),fy(.25),.6*front_scale,.25*65,'#b8aa90')
    rect(fx(xmin),fy(0), (xmax-xmin)*front_scale,13,'#c7cccf')
    # Dimension guides and a deliberately schematic capsule scale marker.
    line(fx(-6),175,fx(6),175,arrows=True);text(640,166,'12,00 м',17,anchor='middle')
    line(fx(-a),495,fx(a),495,arrows=True);text(640,511,'2,40 м',17,anchor='middle')
    line(1068,fy(0),1068,fy(4.12),arrows=True);text(1082,330,'4,12 м',16)
    line(fx(xmin),516,fx(xmax),516,arrows=True);text(640,541,'Площадка 14,00 м · крайние опоры полностью на полу',17,anchor='middle')
    rect(fx(-.35),fy(1.8),.7*front_scale,1.8*65,'#accad2','#417788')
    text(640,fy(1.8)-12,'1,80 м',15,anchor='middle')
    text(64,594,'ПЛАН · -Z сверху · клетки 1 × 1 м',20)
    px=lambda x:405+x*48
    pz=lambda z:754+z*48
    for ix in range(grid['count_x']):
        for iz in range(grid['count_z']): rect(px(xmin+ix),pz(zmin+iz),48,48,'#ece8df','#c6c6bd')
    for lo,hi in [(-6,-2),(-2,-a),(a,2),(2,6)]:rect(px(lo),pz(-.2),(hi-lo)*48,.4*48,'#bdb3a2')
    line(px(-a),pz(-.2),px(a),pz(-.2),'#a07a3b',2,'6 4');line(px(-a),pz(.2),px(a),pz(.2),'#a07a3b',2,'6 4')
    for x,_,z in piers:rect(px(x-.3),pz(z-.3),.6*48,.6*48,'#a78e62')
    for x in probe['center_x_lanes']:
        line(px(x),pz(probe['start_z']),px(x),pz(probe['end_z']),'#417788',2,'4 3',True)
    text(405,885,'Проход: три траектории X = -0,75 / 0 / +0,75 м',16,anchor='middle')
    for y,s in [(640,'СТЫКОВКА'),(674,'4 м = 2 м + 2 м'),(706,'Стена: толщина 0,40 м'),(738,'Проем: пята 2,00 м / верх 3,60 м'),(770,'Опора: 0,60 × 0,60 м'),(802,'56 плит · 63 экземпляра'),(834,'Повороты: 0 / 90 / 180 / 270°')]:text(810,y,s,17)
    line(64,922,1216,922,'#c2c4c3')
    text(64,959,'Контракт: docs/production/modular_archive_kit_v1.json',16)
    text(64,992,'Камень + состаренная латунь · общие материалы · образец не задает планировку игрового хаба',16)
    svg.append('</svg>')
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text('\n'.join(svg)+'\n')
    print('SVG:',output)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contract',type=Path,default=ROOT/'docs/production/modular_archive_kit_v1.json')
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    render(json.loads(args.contract.read_text()),args.output)
