# -*- coding: utf-8 -*-
"""
Created on Mon Jul 19 10:55:29 2021

@author: laura
"""
import numpy as np
import pandas
from scipy import integrate
from flask import Flask, flash, request, redirect, url_for, session, send_file
import argparse
import json
import ast
import sys
import math
import itertools
import colorsys
import os
from types import SimpleNamespace
from matplotlib.colors import to_hex, to_rgb
import xml.dom.minidom as DOM

import os
import re
import shutil

import color_calculation

with open('palette.json', 'r') as fb: 
    palettedata = json.loads(fb.read())
    
# palette = palettedata['palette']
# colorstrings = list(palette.keys())

# print()
# print('colorstrings',colorstrings)
# print("sample color #F6FF53",palette['#F6FF53'])

# path to the directory in which all the images are stored
DATA_PATH = "../data/"

# path to the directory that stores the recolored designs
RECOLORED_PATH = "../data/recolored/"

global_colormatch = dict()
global_newfiles = dict()

def colordist(c1, c2):
    rmean = (c1[0] + c2[0])/2
    r = c1[0]-c2[0]
    g = c1[1]-c2[1]
    b = c1[2]-c2[2]
    return np.sqrt((2+rmean/256)*r**2 + 4*g**2 + (2+(255-rmean)/256)*b**2)

def generatesvgs(designfilename):
    # designfilename = str(request.args.get("filename"))
    filename = DATA_PATH+designfilename
    print(filename)
    newpath = False
    currentcolor = ""
    begin = True #each svg file starts with a few header lines and ends with </svg>
    header = []
    colormatch = dict() # key: color in original design -> value: closest matching polagon color
    colorgroups = dict() # key: polagon color -> value: shapes (in recolored version of the design) corresponding to that color
    
    with open(filename+".svg",'r') as f:
        lines = f.readlines()

    palette = palettedata['palette']
    colorstrings = list(palette.keys())
    print("colorstring", colorstrings)
    
    for l in lines:
        print()
        print("line",l)
        if begin and "<path" not in l:
            header.append(l)
            print("header")
        elif begin and "<path" in l:
            begin = False
            newpath = True
            print("newline")
            
        if l=='<g>\n' or l=='</g>\n': 
            print("pass")
            pass
        
        elif "<path" in l:
            print("pathline")
            newpath = True
            idx= l.find("fill:")
            info = l[idx:len(l)].split('"')
            style = info[0]; #information is split by "", style info is first
            #within the style info, fill/stroke info is split by ";"
            #order is fill, stroke, stroke-width, stroke-miterlimit
            
            items = style.split(';')
            fillc = items[0][5:len(items[0])]
            print("fillc: ",fillc)
            
            if fillc != "none":
            
                if fillc not in colormatch:
                    mindist = 1000
                    # minidx = 0
                    bestmatch = ""
                    # find the closest polagon color to the current color in the svg
                    for j,hexrgb in enumerate(colorstrings):
                        dist = colordist(to_rgb(fillc), to_rgb(hexrgb))
                        if dist < mindist:
                            mindist = dist
                            bestmatch = hexrgb

                    colormatch[fillc] = bestmatch
        
                # replace old fill color with new polage color
                newstyle = "fill:" + colormatch[fillc] + ";"
                info[0] = newstyle
                newline = l[0:idx] + '"'.join(info)
                print("newline",newline)
                
                currentcolor = colormatch[fillc]
                colorgroups[colormatch[fillc]] = colorgroups.get(colormatch[fillc],[])+[newline]
            
            else:
                newpath = False
            
        elif newpath and "/>" in l:
            print("set newpath to false")
            colorgroups[currentcolor] = colorgroups.get(currentcolor,[])+[l]
            newpath = False
        
        elif "<path" not in l and newpath:
            print("other")
            colorgroups[currentcolor] = colorgroups.get(currentcolor,[])+[l]
    
    f.close()
    
    newfiles = []
    
    print()
    print("colorgroup keys", list(colorgroups.keys()))
    
    # create recolored folder if it doesn't exist already
    if not os.path.exists(RECOLORED_PATH):
        os.makedirs(RECOLORED_PATH)
        
    for c in colorgroups:
        # location of the new files
        print("svgfile name",RECOLORED_PATH+designfilename+"_"+c+".svg")
        newfiles.append(RECOLORED_PATH+designfilename+"_"+c+".svg")

        newsvg = open(RECOLORED_PATH+designfilename+"_"+c+".svg",'w')
        newsvg.writelines(header)
        newsvg.writelines(colorgroups[c])
        newsvg.write("</svg>")
        newsvg.close()
    
    global_colormatch[filename] = colormatch
    global_newfiles[filename] = newfiles

    print(colormatch)
    print(newfiles)
# generatesvgs("fire")
    
def getpalette(inverted, boolstring, uniform):
    filterparam = [int(s) for s in boolstring.split(',')]
    filterparam = [True if i!=0 else False for i in filterparam]
    
    if inverted == 1:
        palette = palettedata['palette_inv']
    else:
        palette = palettedata['palette']

    colorstrings = list(palette.keys())
    compositions =[]
    
    filteredcolors = []

    for rgb in colorstrings:
        stack = json.loads(palette[rgb], object_hook=lambda d: SimpleNamespace(**d))
        coefflist = [True if i!=0 else False for i in stack.coeffs]
        if uniform == 1: #want uniform colors
            res1 = all([a == b for a,b in zip(filterparam,coefflist)])
            res2 = all([a == b or (a==True & (a or b)) for a,b in zip(filterparam,coefflist)])
            match = res1 ^ res2
        else:
            match = all([a == b or (a==True & (a or b)) for a,b in zip(filterparam,coefflist)])
        
        if match:
            print(stack.coeffs)
            filteredcolors.append(rgb)
            compositions.append(stack.composition)

    return json.dumps(
        {
            'colorstring': filteredcolors,
            'composition': compositions
        }
    )

# getpalette(0, "1,0,0,1,0", 1)      
# print(getpalette(0, "1,0,0,1,0", 0))



def dist(x,y):
    return np.sqrt(x^2+y^2)

test1 = [1,6,47,14,26,4]
value = 5


# test2=sorted(test1, key=lambda x: dist(x,value)) 
# print(test1)
# print(test2)







def compare(x,y):
    print(x,y)
    if x == 0 & x==y:
        return True
    elif x !=0 & y!= 0:
        return True
    else:
        return False
    
# result = all(map(compare, boollist, coefflist))
# print(result)

# filtered_list = [i for (i,v) in enumerate(boollist) if v==1]
# print(filtered_list)

# for getting all results that match the selection

boollist = [1,1,1,1,1]
coefflist = [3,0,3,0,0]
x = [True if i!=0 else False for i in boollist]
y = [True if i!=0 else False for i in coefflist]
# print("boollist",x)
# print("coeflist",y)
# result = all([a == b for a,b in zip(x,y)])
# print(result)

filterparam=x
coefflist=y

sumcoeff=sum([1 if i!=0 else 0 for i in coefflist])
res1 = all([a == b for a,b in zip(filterparam,coefflist)])
res2 = all([a == b or (a==True & (a or b)) for a,b in zip(filterparam,coefflist)])
match = res1 ^ res2 and sumcoeff==1

print(res1,res2,match)
# result2= all([a == b or (a==True & (a or b)) for a,b in zip(x,y)])
# print(result2)

# uniform = result ^ result2
# print(uniform)


# uniformlists = []
# posidx = [i for (i,v) in enumerate(filterparam) if v==1]
# for idx in posidx:
#     filterlist = [0]*len(cellophanedict)
#     filterlist[idx] = 1
#     uniformlists.append(filterlist)

# colorstrings = list(palette.keys())
# compositions =[]
# filteredcolors = []

# for rgb in colorstrings:
#     match=False;
    
#     stack = json.loads(palette[rgb], object_hook=lambda d: SimpleNamespace(**d))
#     coefflist = stack.coeffs
    
#     if uniform==0:
#         uniformlists.append(filterparam)     
        
#     for ul in uniformlists:
#         match = sum(coefflist) == sum(np.multiply(ul,coefflist))
#         if match:
#             filteredcolors.append(rgb)
#             compositions.append(stack.composition)




