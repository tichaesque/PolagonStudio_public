# Python backend code for Polagons

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
from statistics import pstdev
import copy
import os
import re
import shutil
import sys
from cairosvg import svg2png
from PIL import Image

import color_calculation


'''
CONSTANTS & SETUP
'''

# Configure the service as a webserver hosting a REST API
app = Flask(__name__)
args = None

global_colormatch = dict()
global_newfiles = dict()
global_laserfiles = dict()
global_mapping = dict()


# path to the directory in which all the images are stored
DATA_PATH = "../data/"

# path to the directory that stores the recolored designs
RECOLORED_PATH = "../data/recolored/"

# path to the directory that stores the snapshot pngs
SNAPSHOT_PATH = "../data/snapshot/"
png_basewidth = 100

# path to the directory that stores the laser cut ready files
CUT_PATH = "../data/cut/"
SVG_SHAPE_ELEMENTS = ['circle', 'rect', 'ellipse', 'polygon', 'polyline', 'path']
CUT_STYLE = 'fill:none;stroke:red;stroke-width:0.0001px'

sys.setrecursionlimit(100000)

# create recolored folder if it doesn't exist already
if not os.path.exists(RECOLORED_PATH):
    os.makedirs(RECOLORED_PATH)

# create cut folder if it doesn't exist already
if not os.path.exists(CUT_PATH):
    os.makedirs(CUT_PATH)
    
# create snapshot folder if it doesn't exist already
if not os.path.exists(SNAPSHOT_PATH):
    os.makedirs(SNAPSHOT_PATH)
if not os.path.exists(SNAPSHOT_PATH+"svg/"):
    os.makedirs(SNAPSHOT_PATH+"svg/")
    

with open('palette.json', 'r') as fb:
    palettedata = json.loads(fb.read())

cellophanedict = {float(k):v for k,v in palettedata['cellophanedict'].items()}
cellophanethicknesses = list(cellophanedict.keys()) #thicknesses are in nm
numcellophane = len(cellophanethicknesses)

# active design files
# key: design file name, value: 1 if using crossed polarizers, 0 otherwise
activefiles = {}

# check how visually similar two colors are to each other
# from https://www.compuphase.com/cmetric.htm
def colordist(c1, c2):
    rmean = (c1[0] + c2[0])/2
    r = c1[0]-c2[0]
    g = c1[1]-c2[1]
    b = c1[2]-c2[2]
    return np.sqrt((2+rmean/256)*r**2 + 4*g**2 + (2+(255-rmean)/256)*b**2)

@app.route('/updatecellophanedict', methods=['GET'])
def updatecellophanedict():
    global cellophanedict
    thickness = float(request.args.get("thickness"))
    biref = float(request.args.get("biref"))

    cellophanedict[thickness] = biref
    print("cellophane dict: ", cellophanedict)

    return 'OK'

@app.route('/getcellophanedict', methods=['GET'])
def getcellophanedict():
    thicknesses = str(list(cellophanedict.keys()))
    return thicknesses[1:-1]

@app.route('/generatesvgs', methods=['GET'])
def generatesvgs():
    designfilename = str(request.args.get("filename"))
    filename = DATA_PATH+designfilename
    basename = designfilename[0:len(designfilename)-4]
    useinverted = int(request.args.get("inverted")) # recolor image based on crossed polarizer palette (in case the user wants to use black)
    selected = str(request.args.get("selected"))
    uniform = int(request.args.get("uniform"))

    if request.args.get("origcolor")!=None:
        oldcolor = "#"+str(request.args.get("origcolor"))
        newcolor = "#"+str(request.args.get("newcolor"))
        mapping = {oldcolor:newcolor}
        if filename not in global_mapping:
            global_mapping[filename] = mapping
        else:
            global_mapping[filename] = {**global_mapping[filename], **mapping}
        print("oldcolor", oldcolor)
        print("newcolor", newcolor)
        print("global_mapping", global_mapping)

    colormatch = dict() # key: color in original design -> value: closest matching polagon color
    colorgroups = dict() # key: polagon color -> value: shapes (in recolored version of the design) corresponding to that color

    palette = palettedata['palette']
    activefiles[designfilename] = 0
    if useinverted == 1:
        palette = palettedata['palette_inv']
        activefiles[designfilename] = 1

    filtered_result = filter_colors(palette, selected, uniform)
    colorstrings = filtered_result["colorstring"]

    svgroot = flattenSVGLayers(filename)

    for shape in svgroot.childNodes:

        if shape.nodeType != shape.TEXT_NODE:
            fillc = getsvgshapefill(shape)

            if fillc != 'none':
                if fillc not in colormatch:


                    if filename in global_mapping and fillc in global_mapping[filename]:
                        colormatch[fillc] = global_mapping[filename][fillc]

                    else:
                        mindist = 1000

                        bestmatch = ""
                        # find the closest polagon color to the current color in the svg
                        for j,hexrgb in enumerate(colorstrings):
                            dist = colordist(to_rgb(fillc), to_rgb(hexrgb))
                            if dist < mindist:
                                mindist = dist
                                bestmatch = hexrgb

                        colormatch[fillc] = bestmatch

                if colormatch[fillc] not in colorgroups:
                    colorgroups[colormatch[fillc]] = svgroot.cloneNode(False)

                colorgroups[colormatch[fillc]].appendChild(shape.cloneNode(True))

    newfiles = []

    outputpath = RECOLORED_PATH + designfilename + '/'
    if os.path.exists(outputpath):
        shutil.rmtree(outputpath)
    os.makedirs(outputpath)


    for col, shapes in colorgroups.items():
        newfilename = outputpath+basename+"_"+col+".svg"
        newfiles.append(newfilename)

        with open(newfilename, 'w') as f_out:
            f_out.write(shapes.toxml())

    global_colormatch[filename] = colormatch
    global_newfiles[filename] = newfiles

    print("global_newfiles", global_newfiles)
    print("global_colormatch", global_colormatch)
    print("colorgroups", colorgroups)

    return json.dumps("OK")

# img1 = background image, img = foreground image
# https://stackoverflow.com/questions/56866759/how-to-paste-a-small-image-on-another-big-image-at-center-in-python-with-an-imag
def pasteontop(img1, img, filename):
	# calibrating the bbox for the beginning and end position of the cropped image in the original image 
	# i.e the cropped image should lie in the center of the original image
	x1 = int(.5 * img1.size[0]) - int(.5 * img.size[0])
	y1 = int(.5 * img1.size[1]) - int(.5 * img.size[1])
	x2 = int(.5 * img1.size[0]) + int(.5 * img.size[0])
	y2 = int(.5 * img1.size[1]) + int(.5 * img.size[1])

	# pasting the cropped image over the original image, guided by the transparency mask of cropped image
	img1.paste(img, box=(x1, y1, x2, y2), mask=img)

	# converting the final image into its original color mode, and then saving it
	img1.convert(img1.mode).save(filename)

def composite(mosaic1, mosaic2, mask, mosaic1rot, mosaic2rot, maskrot, theta, phi, filename):
	# Note: lines 32-36 are not necessary if the mosaic/mask images are already rotated
    mosaic1rotated = mosaic1.rotate(-mosaic1rot, resample=Image.BICUBIC)
    if mosaic2 is not None:
        mosaic2rotated = mosaic2.rotate(-mosaic2rot, resample=Image.BICUBIC)
        mosaic1rotated.paste(mosaic2rotated, (0,0), mosaic2rotated)        
    if mask is not None: 
        maskrotated = mask.rotate(-maskrot, resample=Image.BICUBIC)
        mosaic1rotated.paste(maskrotated, (0,0), maskrotated)

	#####

	# adjust arrow rotation
    analyzer = Image.open('../graphics/analyzerarrow.png')
    polarizer = Image.open('../graphics/polarizerarrow.png')
    analyzer2 = analyzer.rotate(-theta, resample=Image.BICUBIC)
    polarizer2 = polarizer.rotate(-phi, resample=Image.BICUBIC)
    polarizer2.paste(analyzer2, (0,0), analyzer2)

    pasteontop(polarizer2, mosaic1rotated, filename)
             
@app.route('/updatesvg', methods=['GET'])
def updatesvg():
    all_files = str(request.args.get("filename"))
    
    # dont need these values anymore
    delta = np.degrees(float(request.args.get("delta")))
    maskdelta = np.degrees(float(request.args.get("maskdelta")))
    phi = np.degrees(float(request.args.get("phi")))
    theta = np.degrees(float(request.args.get("theta")))
    # bgcolor = "#"+str(request.args.get("background"))
    
    # info format: "(fill1, opacity1);(fill2,opacity2);..."
    img1_info = request.args.get("img1_info")
    img1_info = [("#"+x.strip(")(").split(",")[0],float(x.strip(")(").split(",")[1])) for x in img1_info.split(";")]
    
    img2_info = request.args.get("img2_info")
    if img2_info != "":
        img2_info = [("#"+x.strip(")(").split(",")[0],float(x.strip(")(").split(",")[1])) for x in img2_info.split(";")]
    # else:
    #     mosaic2 = None
        
    mask_info = request.args.get("mask_info")
    # if mask_info == "": mosaic_mask = None
    
    # CHANGES
    # split filename and create a folder for each file
    # put svg folder elsewhere to avoid confusion
    # make png of each separate design
    # simplify filenames
    

    svg_outputpath = SNAPSHOT_PATH + "svg/" + all_files + '/'
    png_outputpath = SNAPSHOT_PATH + all_files + "/"
    if not os.path.exists(svg_outputpath):
        os.makedirs(svg_outputpath)
    if not os.path.exists(png_outputpath):
        os.makedirs(png_outputpath)
    
    dirfiles = os.listdir(png_outputpath)
    if dirfiles == []:
        counter = 1
    else:
        numfiles = [int(f.split("_")[0]) for f in dirfiles]
        counter = max(numfiles) + 1
        
    files = all_files.split(";")
    files = [files[i] if i<len(files) else "" for i in range(3)]

    items = ["mosaic1", "mosaic2", "mask"]
    angles = [delta, delta, maskdelta]
    file_info = list(zip(files,items,[img1_info, img2_info, mask_info],angles))

    
    all_svg_shapes = dict() # dictionary for storing shapes to create respective svgs
    mosaics = dict() # dictionary for holding png files for composite
    
    for info in file_info:
        name, item, shapeinfo, angle = info[0], info[1], info[2], info[3]
        svg_shapes = dict()
        if shapeinfo!="":
            print("nonempty string name", name)
            buildsvgdoc(svg_shapes,name,shapeinfo)
            buildsvgdoc(all_svg_shapes,name,shapeinfo)
            outname = str(counter) + "_" + name.split(".")[0]
            newfilename = svg_outputpath+outname+".svg"
            pngout = png_outputpath+outname+".png"
            with open(newfilename, 'w') as f_out:
                f_out.write(svg_shapes[name].toxml())
    
            svg2png(url=newfilename, write_to=pngout)
            
            # resize png
            png = Image.open(pngout)
            wpercent = (png_basewidth/float(png.size[0]))
            hsize = int((float(png.size[1])*float(wpercent)))
            png = png.resize((png_basewidth,hsize), Image.ANTIALIAS)
            
            png.save(pngout)
            mosaics[item] = png
            
            png = png.rotate(-angle, resample=Image.BICUBIC)
            png.save(pngout)
            
            
        else:
            mosaics[item] = None
            
    print("mosaic dict", mosaics)
    
    outname = str(counter) + "_composite"
    newfilename = svg_outputpath+outname+".svg"
    # pngout = png_outputpath+outname+".png"
    pngout = SNAPSHOT_PATH +"snapshot.png"
    
    composite(mosaics["mosaic1"], mosaics["mosaic2"], mosaics["mask"], delta, delta, maskdelta, theta, phi, pngout)
    
    # all_svg_shapes[all_files] = all_svg_shapes[files[0]].appendChild(all_svg_shapes[files[0]].cloneNode(False))
    # for name in all_svg_shapes:
    #     all_svg_shapes[all_files].appendChild(all_svg_shapes[name].cloneNode(True))
    
    # print(all_svg_shapes)
            
    # with open(newfilename,"w") as f_out:
    #     f_out.write(all_svg_shapes[files[0]].toxml())
    # svg2png(url=newfilename, write_to=pngout)
    # # resize png
    # png = Image.open(pngout)
    # wpercent = (png_basewidth/float(png.size[0]))
    # hsize = int((float(png.size[1])*float(wpercent)))
    # png = png.resize((png_basewidth,hsize), Image.ANTIALIAS)
    # png.save(pngout)
    
    return json.dumps("OK")
    
    

# flattens layers in SVG file and removes title tag
def flattenSVGLayers(filename):
    doc = DOM.parse(filename)
    svgroot = doc.getElementsByTagName('svg')[0]

    titles = svgroot.getElementsByTagName('title')
    for title in titles:
        svgroot.removeChild(title)

    layers = doc.getElementsByTagName('g')

    for layer in layers:
        children = [child for child in layer.childNodes]

        for child in children:
            child = layer.removeChild(child)
            svgroot.appendChild(child)

        svgroot.removeChild(layer)


    children = [child for child in svgroot.childNodes]

    for child in children:
        if child.nodeType == child.TEXT_NODE:
            svgroot.removeChild(child)


    return svgroot

def getsvgshapefill(shape):
    style = shape.getAttribute('style')
    r = re.search(r'fill:\s*#(?:[0-9a-fA-F]{3}){1,2}', style)
    fill = 'none'
    if r is not None:
      fill = r.group(0)

      # return fill[5:]
      return fill[-7:]
    return fill

def buildsvgdoc(svg_shapes,svgname,img_info):
    if (DATA_PATH+svgname) not in global_newfiles:
        print("mask file:", svgname)
        maskroot = flattenSVGLayers(DATA_PATH+svgname)
        maskshape = maskroot.childNodes[0]
        maskshape.setAttribute("style","fill:#000000;fill-opacity:"+img_info+";")
        if svgname not in svg_shapes:
            svg_shapes[svgname] = maskroot.cloneNode(False)
        svg_shapes[svgname].appendChild(maskshape.cloneNode(True))
    
    else:
        print("design file:", svgname)
        svgfiles = global_newfiles[DATA_PATH+svgname]
        for info in zip(svgfiles,img_info):
            file, fill, opac = info[0], info[1][0], info[1][1]
            svgroot = flattenSVGLayers(file)
            for shape in svgroot.childNodes:
                if shape.nodeType != shape.TEXT_NODE:
                    changesvgshapefill(shape, fill, opac)
                    if svgname not in svg_shapes:
                         svg_shapes[svgname] = svgroot.cloneNode(False)
                    svg_shapes[svgname].appendChild(shape.cloneNode(True))
    
def changesvgshapefill(shape, color, alpha):
    newstyle = "fill:"+color+";fill-opacity:"+str(alpha)+";"
    shape.attributes["style"].value = newstyle

@app.route('/getorigcolors', methods=['GET'])
def getorigcolors():
    filename = DATA_PATH+request.args.get("filename")

    origcolors = list(global_colormatch[filename].keys())
    return json.dumps({"colorstring": origcolors})

@app.route('/getpolagecolors', methods=['GET'])
def getpolagecolors():
    filename = DATA_PATH+request.args.get("filename")
    polagecolors = list(global_colormatch[filename].values())

    return json.dumps({"colorstring": polagecolors})

@app.route('/clearmapping', methods=['GET'])
def clearmapping():
    global_mapping.clear()
    return json.dumps("OK")

def validsolutions(valid, thicknesses, coeff, maxval):
    thickness = 0
    for i, c in enumerate(coeff):
        thickness += thicknesses[i]*c

    if thickness <= maxval:
        if len(coeff) == len(thicknesses):
            if thickness > 0:
                valid.append(coeff[:])
        else:
            newcoeffs = list(range(0, math.ceil((maxval-thickness)/thicknesses[len(coeff)])))
            for newc in newcoeffs:
                coeff.append(newc)
                validsolutions(valid, thicknesses, coeff, maxval)
                coeff.pop()

def computethickness(thicknesses, coeff):
    zvalue = 0
    for i,c in enumerate(coeff):
        zvalue += thicknesses[i]*c

    return zvalue

# generates a message that expresses the layer composition for a given color
def colorcomposition(thicknesses, coeff):
    result = ''
    totalthickness = 0
    for idx, c in enumerate(coeff):
        if c > 0:
            thicknessmm = thicknesses[idx]/1e6
            result = result + str(c)+'x '+ str(thicknessmm)+'mm\n'
            totalthickness = totalthickness + thicknessmm*c

    return 'total thickness: '+'{:.3f}'.format(totalthickness)+'mm\n'+result, totalthickness

class CellophaneStack:
    def __init__(self, composition_, numsheets_, thickness_, coeffs_, zvalues_):
        self.composition = composition_
        self.numsheets = numsheets_
        self.thickness = thickness_
        self.coeffs = coeffs_
        self.zvalues = zvalues_

    def toJSON(self):
        return json.dumps(self, default=lambda o: o.__dict__,
            sort_keys=True, indent=4)

# compute number of nonzero values in list
def nnz(coeffs):
    return sum(1 for x in coeffs if x != 0)

@app.route('/generatepalette', methods=['GET'])
def generatepalette():
    theta = np.pi/4

    global palettedata


    thicknesses = list(cellophanedict.keys()) # units in nm
    birefs = list(cellophanedict.values())

    print("thicknesses: ", thicknesses)

    maxthickness = .25e6 # colors become muddy/indistinguishable after this point
    coefficients = []
    valid = []
    colors = []

    print("exploring valid solutions...")
    validsolutions(valid, thicknesses, coefficients, maxthickness)
    valid.sort(key=lambda x : computethickness(thicknesses, x))
    print("valid: ", valid)

    print("# unfiltered colors: ", len(valid))


    graytol = 0 # tolerance for filtering out gray values
    mindist = 0 # tolerance for filtering out similar hues

    palette = {} # aligned polarizers
    palette_inv = {} # crossed polarizers
    color_lookup = {} # key: coefficient list, value: (rgb_aligned, rgb_crossed)

    for coeff in valid:
        zvalues = [a * b for a, b in zip(thicknesses, coeff)]

        colorstr = input2rgb2(theta,theta,birefs,zvalues,1)
        colorstr = colorstr.strip()
        r,g,b = list(map(float, colorstr.split()))

        compstring, totalthickness = colorcomposition(thicknesses, coeff)
        stack = CellophaneStack(compstring, sum(coeff), totalthickness, coeff, zvalues)

        rgbhex = to_hex([r/255, g/255, b/255]).upper()

        if rgbhex not in palette:
            palette[rgbhex] = stack.toJSON()
        else:
            # if this rgb value already exists in the palette and we found a combo
            # that uses fewer kinds of cellophane, pick that combo
            storedstack = json.loads(palette[rgbhex], object_hook=lambda d: SimpleNamespace(**d))

            # pick the stack with the lower layer count
            if sum(coeff) < sum(storedstack.coeffs):
                palette[rgbhex] = stack.toJSON()

            elif sum(coeff) == sum(storedstack.coeffs) and nnz(coeff) < nnz(storedstack.coeffs):
                palette[rgbhex] = stack.toJSON()

        colorstr2 = input2rgb2(theta,theta+np.pi/2,birefs,zvalues,1)
        colorstr2 = colorstr2.strip()
        r_i,g_i,b_i = list(map(float, colorstr2.split()))
        rgbhex_i = to_hex([r_i/255, g_i/255, b_i/255]).upper()
        palette_inv[rgbhex_i] = palette[rgbhex]

        color_lookup[str(coeff)] = (rgbhex, rgbhex_i)

    palettedata = {
                'cellophanedict':cellophanedict,
                'thicknesses':json.dumps(thicknesses),
                'birefs':json.dumps(birefs),
                'palette':palette,
                'palette_inv':palette_inv,
                'color_lookup':color_lookup
            }

    with open('palette.json', 'w') as fp:
        fp.write(json.dumps(palettedata))

    print("# filtered colors: ", len(palette))

    return 'OK'

def filter_colors(palette, selected, uniform):
    filterparam = [int(s) for s in selected.split(',')]

    colorstrings = list(palette.keys())
    compositions = []
    filteredcolors = []

    for rgb in colorstrings:
        stack = json.loads(palette[rgb], object_hook=lambda d: SimpleNamespace(**d))

        coefflist = [True if i!=0 else False for i in stack.coeffs]
        match = all(not a or b for a,b in zip(coefflist, filterparam))

        if uniform:
            match = match and nnz(stack.coeffs) == 1

        if match:
            filteredcolors.append(rgb)
            compositions.append(stack.composition)

    return {
            'colorstring': filteredcolors,
            'composition': compositions
            }


@app.route('/getpalette', methods=['GET'])
def getpalette():
    inverted = int(request.args.get("inverted"))
    selected = str(request.args.get("selected"))
    uniform = int(request.args.get("uniform"))

    if inverted == 1:
        palette = palettedata['palette_inv']
    else:
        palette = palettedata['palette']


    filtered_res = filter_colors(palette, selected, uniform)

    return json.dumps(filtered_res)

@app.route('/sortpalette', methods=['GET'])
def sortpalette():
    inverted = int(request.args.get("inverted"))
    selected = str(request.args.get("selected"))
    uniform = int(request.args.get("uniform"))
    polagecolor = '#'+str(request.args.get("polagecolor"))
    print("polagecolor", polagecolor)

    if inverted == 1:
        palette = palettedata['palette_inv']
    else:
        palette = palettedata['palette']


    filtered_res = filter_colors(palette, selected, uniform)

    combined = zip(filtered_res['colorstring'], filtered_res['composition'])

    sortedcombined = sorted(combined, key=lambda x: colordist(to_rgb(polagecolor), to_rgb(x[0])))

    sorted_res = {'colorstring': [i for i,j in sortedcombined],
                  'composition': [j for i,j in sortedcombined]
        }

    return json.dumps(sorted_res)

@app.route('/lookupcolor', methods=['GET'])
def lookupcolor():
    coeffs = list(map(int, request.args.get("composition").split('~')))
    color_lookup = palettedata['color_lookup']
    rgb, rgb_i = color_lookup[str(coeffs)]

    return json.dumps(
        {
            'rgb': rgb,
            'rgb_i': rgb_i
        }
    )

@app.route('/getsvgfiles', methods=['GET'])
def getsvgfiles():
    designfilename = request.args.get("filename")

    filename = DATA_PATH + designfilename
    svgfiles = str(global_newfiles[filename])
    print(svgfiles)
    return svgfiles[1:-1] #remove brackets at beginning & end


# multiple birefringence values
def input2rgb2(theta, phi, biref, z, E0):
    X,Y,Z = color_calculation.tristimulus_values2(theta, phi, biref, z, E0)
    RGB = color_calculation.XYZtoRGB2(X,Y,Z)
    intostring = str(RGB*255)
    return intostring[1:-1]

# single birefringence value
def input2rgb(theta, phi, biref, z, E0):
    X,Y,Z = color_calculation.tristimulus_values(theta, phi, biref, z, E0)
    RGB = color_calculation.XYZtoRGB2(X,Y,Z)
    intostring = str(RGB*255)
    return intostring[1:-1]

@app.route('/getcolor', methods=['GET'])
def getcolor():
    theta = float(request.args.get("theta"))
    phi = float(request.args.get("phi"))
    biref = float(request.args.get("biref"))
    z = float(request.args.get("thickness"))
    E0 = 1

    colorstr = input2rgb(theta,phi,biref,z,E0)
    return json.dumps(colorstr)

@app.route('/getcolor2', methods=['GET'])
def getcolor2():
    theta = float(request.args.get("theta"))
    phi = float(request.args.get("phi"))
    z = list(map(float,request.args.get("zvalues").split('~')))
    biref = json.loads(palettedata['birefs'])

    E0 = 1
    colorstr = input2rgb2(theta,phi,biref,z,E0)

    return json.dumps(colorstr)

def getcolorserver(theta, phi, zvalues):
    biref = json.loads(palettedata['birefs'])
    E0 = 1
    colorstr = input2rgb2(theta,phi,biref,zvalues,E0)

    return colorstr

# for computing birefringence
@app.route('/getcolortest', methods=['GET'])
def getcolortest():
    theta = float(request.args.get("theta"))
    phi = float(request.args.get("phi"))
    coeffs = list(map(float,request.args.get("coeffs").split('~')))
    z = [a*b for a,b in zip(coeffs, list(cellophanedict.keys()))]
    biref = list(cellophanedict.values())

    E0 = 1
    colorstr = input2rgb2(theta,phi,biref,z,E0)

    return json.dumps(colorstr)

# returns the zvalues (thicknesses) for the constituent sheets of the cellophane stack
@app.route('/stackcomposition', methods=['GET'])
def stackcomposition():
    basecolor = request.args.get("colorkey")
    palette = palettedata['palette']
    designfile = request.args.get("filename")
    if activefiles[designfile] == 1:
        palette = palettedata['palette_inv']

    stack = json.loads(palette['#'+basecolor], object_hook=lambda d: SimpleNamespace(**d))
    return json.dumps(stack.zvalues)

@app.route('/childlayers', methods=['GET'])
def childlayers():
    hexval = str(request.args.get("hexval"))
    layers = polagecolordict['#'+hexval]

    return json.dumps(str(layers))

@app.route('/childthickness', methods=['GET'])
def childthickness():
    hexval = str(request.args.get("hexval")) #the hexval from processing is preceded by 2 Fs so remove those
    hexval = '#' + hexval[2:len(hexval)]
    z = polagecolordict[hexval] * layer_t

    return json.dumps(str(z))

# Prepare the relevant design files for cutting. This consists in
# changing the style of the SVG elements to the appropriate
# fill and stroke to be interpreted by the laser cutter.
#
# Returns: The filename of the prepared version of the file

# Prepare the relevant design files for cutting
@app.route('/generate_laserfiles', methods=['GET'])
def generate_laserfiles():
    epsilon = float(request.args.get("epsilon")) * 1e6 # thickness difference tolerance in nm
    laserw = request.args.get("laserw")
    laserh = request.args.get("laserh")
    laserunit = request.args.get("laserunit")
    designfile = request.args.get("filename")
    rotation = int(request.args.get("rotation"))

    readpath = RECOLORED_PATH + designfile + '/'

    files = [filename for filename in os.listdir(readpath) if filename.startswith(designfile[:-4])]
    coeff_dict = {}
    zvalues_dict = {}
    numfiles = len(files)

    palette = palettedata['palette']
    if activefiles[designfile] == 1:
        palette = palettedata['palette_inv']

    for filename in files:
        hexval = filename.split('_')[1][:-4]

        stack = json.loads(palette[hexval], object_hook=lambda d: SimpleNamespace(**d))
        coeffs = stack.coeffs
        zvalues = stack.zvalues
        coeff_dict[filename] = coeffs
        zvalues_dict[filename] = zvalues

    order = 1
    outputfiles = []

    for i in range(numcellophane):
        found = True
        layernum = 0

        while found:
            found = False
            svgout = {}

            # filename = color group
            for filename in files:
                coeffs = coeff_dict[filename]
                zvalues = zvalues_dict[filename]

                if coeffs[i] > layernum: # ensures that you are not adding more layers of cellophane type i than you need
                    thickness = sum(zvalues[:i]) + (layernum + 1)*cellophanethicknesses[i]

                    found = True

                    # add shapes to active PDF
                    doc = DOM.parse(readpath + filename)
                    svgroot = doc.getElementsByTagName('svg')[0]

                    if thickness not in svgout:
                        svgout[thickness] = svgroot.cloneNode(False)


                    for child in svgroot.childNodes:
                        svgout[thickness].appendChild(child.cloneNode(True))

            # write to svg file
            if found:
                layernum = layernum + 1

                svgfile = DOM.parse(os.path.join(readpath,files[0])).getElementsByTagName('svg')[0].cloneNode(False) # for UI viewing
                cutfile = DOM.parse(os.path.join(readpath,files[0])).getElementsByTagName('svg')[0].cloneNode(False) # for UI viewing # for sending to laser cutter

                prevthickness = 0

                for t in sorted(svgout.keys()):
                    # add shapes that are within the tolerance value
                    if prevthickness == 0 or abs(t-prevthickness) <= epsilon:
                        for child in svgout[t].childNodes:
                            svgfile.appendChild(child.cloneNode(True))
                            cutfile.appendChild(child.cloneNode(True))

                        if prevthickness == 0:
                            prevthickness = t
                    else:

                        newfilename = '{}mm-height{}mm'.format(cellophanethicknesses[i]/1e6,prevthickness/1e6)


                        outputfiles.append((prevthickness, i, newfilename, cutfile, svgfile))

                        # update active SVG file
                        svgfile = svgout[t]

                        prevthickness = t

                newfilename = '{}mm-height{}mm'.format(cellophanethicknesses[i]/1e6,prevthickness/1e6)

                outputfiles.append((prevthickness, i, newfilename, cutfile, svgfile))


    outputpath = CUT_PATH + designfile + '/'
    UIoutputpath = outputpath + "UI/"
    if os.path.exists(outputpath):
        shutil.rmtree(outputpath)
    os.makedirs(outputpath)
    if os.path.exists(UIoutputpath):
        shutil.rmtree(UIoutputpath)
    os.makedirs(UIoutputpath)

    newlaserfiles = []

    shape_dict = {}
    for order, (thickness, cellophaneindex, newfilename, file_contents, UIfile_contents) in enumerate(sorted(outputfiles)):
        UIfilename = UIoutputpath + str(order+1) +"-"+newfilename
        newfilename = outputpath + str(order+1) +"-"+newfilename

        with open(newfilename + ".svg", 'w') as f_out:
            cutfilexml = prepare_for_output(UIfile_contents, rotation, False, laserw, laserh, laserunit, cellophanethicknesses[cellophaneindex]/1e6)
            f_out.write(cutfilexml)
            # f_out.write(file_contents.toxml())
        newlaserfiles.append(newfilename + ".svg")

        # write UI svg file
        with open(UIfilename+"-UI.svg",'w') as f_out:
            svgfilexml = prepare_for_output(UIfile_contents, rotation, True, laserw, laserh, laserunit)
            f_out.write(svgfilexml)
            # f_out.write(UIfile_contents.toxml())

        svgroot = UIfile_contents
        shape_dict2 = {k:(c[:],svg.cloneNode(True)) for k,(c,svg) in shape_dict.items()}

        for child in svgroot.childNodes:
            childxml = child.toxml()
            if childxml not in shape_dict:
                shape_dict[childxml] = ([], child.cloneNode(False))
                shape_dict2[childxml] = ([], child.cloneNode(False))

            shape_dict[childxml][0].append(cellophaneindex)

        for _, (cellophanelist,_) in shape_dict2.items():
            cellophanelist.append(cellophaneindex)


    global_laserfiles[designfile] = newlaserfiles
    print(global_laserfiles[designfile])

    return str(len(newlaserfiles))

def coloroutputshapes(svgroot, shape_dict):
    coloredsvg = svgroot.cloneNode(False)
    for shapexml, (cellophanelist,shaperoot) in shape_dict.items():
        zvalues = [cellophanelist.count(a)*cellophanethicknesses[a] for a in range(numcellophane)]

        colorstr = getcolorserver(np.pi/4, np.pi/4, zvalues)
        r,g,b = map(int, map(float, colorstr.split()))
        hexrgb = '#%02x%02x%02x' % (r,g,b)
        shaperoot.setAttribute('style', "fill:{};".format(hexrgb.upper()))

        coloredsvg.appendChild(shaperoot)

    return coloredsvg

@app.route('/generate_mask_laserfiles', methods=['GET'])
def generate_mask_laserfiles():
    maskfile = request.args.get("filename")

    doc = DOM.parse(os.path.join(DATA_PATH, maskfile))
    svgroot = doc.getElementsByTagName('svg')[0]
    svgout = svgroot.cloneNode(False)

    outputfile = prepare_for_output(svgroot, -90, True, 0, 0, 0)
    outputfilexml = outputfile

    outputpath = CUT_PATH + maskfile

    with open(outputpath, 'w') as f_out:
        f_out.write(outputfilexml)

    return 'OK'

def prepare_for_output(svgfile, rotation, UI, laserw, laserh, laserunit, thickness = None):
    # save active file to SVG that needs to be printed
    # group shapes and rotate by 45 degrees

    doc = DOM.Document()
    _,_,width,height = map(float, svgfile.getAttribute('viewBox').split())
    diagonal = np.sqrt(width**2 + height**2)
    translatey = (diagonal-height)/2
    translatex = (diagonal-width)/2
    newwidth, newheight = width*2, height*2 # add some padding to account for rotation

    svgfileclone = svgfile.cloneNode(True)

    groupelem = doc.createElement('g')
    groupelem.setAttribute('transform', 'translate({} {}) rotate({} {} {})'.format(translatex,translatey,rotation, width/2,height/2))

    update(svgfileclone)

    if not UI:
        children = [child for child in svgfileclone.childNodes]

        for child in children:
            child = svgfileclone.removeChild(child)

            num_copies = int(math.floor(thickness / 0.01)) if thickness is not None else 1
            for _ in range(num_copies):
                groupelem.appendChild(child.cloneNode(True))

        svgfileclone.appendChild(groupelem)

        svgfileclone.removeAttribute('viewBox')
        svgfileclone.removeAttribute('style')
        svgfileclone.setAttribute('width', laserw+laserunit)
        svgfileclone.setAttribute('height', laserh+laserunit)


    return svgfileclone.toxml()


@app.route('/getlaserfiles', methods=['GET'])
def getlaserfiles():
    designfilename = request.args.get("filename")
    svgfiles = str(global_laserfiles[designfilename])
    print("svgfiles", svgfiles)
    return svgfiles[1:-1] #remove brackets at beginning & end

def update(node):
    if node.nodeType != node.TEXT_NODE:
        if node.tagName in SVG_SHAPE_ELEMENTS:
            node.setAttribute('style', CUT_STYLE)

        elif node.tagName == 'g' or node.tagName == 'svg':
            for child in node.childNodes:
                update(child)


if __name__ == "__main__":
  argparser = argparse.ArgumentParser()
  argparser.add_argument('--port', dest='port', default=3000, type=int, help='Port to serve the local service on')
  args = argparser.parse_args()

  # Run the flask application locally. This server should never serve to the outside world
  app.run(host='127.0.0.1', port=args.port)
