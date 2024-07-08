
import numpy as np
import pandas
from scipy import integrate
import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from pprint import pprint

theta = np.pi/4
phi = np.pi/4
# for my 2.3 Mil cellophane, biref = 0.0062
# biref = 0.0152
biref = 0.0062
# z = 58420 #unit nm, 1 layer of 2.3Mil cellophane
z = 45000 # 1 layer of 0.045mm cellophane

E0 = 1

df = pandas.read_csv('ciexyz31_1.csv',header=0,names=['wavelength','xbar','ybar','zbar'])
lb = df.wavelength <= 780
ub = df.wavelength >= 380
colorfunc = df[lb&ub]

def transmittance(theta, phi, biref, z, wavelen):
    term1 = pow(np.sin(theta),2)*pow(np.sin(phi),2)
    term2 = pow(np.cos(theta),2)*pow(np.cos(phi),2)
    z_eff = biref*z
    term3 = 0.5*np.sin(2*theta)*np.sin(2*phi)*np.cos(2*np.pi*z_eff/wavelen)
    return term1+term2+term3

# transmittance equation for multiple birefringent values
# biref[i] corresponds to the birefringence of the sheet with thickness z[i]
def transmittance2(theta, phi, biref, z, wavelen):
    term1 = pow(np.sin(theta),2)*pow(np.sin(phi),2)
    term2 = pow(np.cos(theta),2)*pow(np.cos(phi),2)
    z_eff = sum([a * b for a, b in zip(biref, z)])
    term3 = 0.5*np.sin(2*theta)*np.sin(2*phi)*np.cos(2*np.pi*z_eff/wavelen)
    return term1+term2+term3


def tristimulus_values(theta, phi, biref, z, E0):
    I = E0*transmittance(theta,phi,biref,z,colorfunc.wavelength)
    # print(np.size(colorfunc.xbar), np.size(I), np.size(colorfunc.xbar*I))
    # print("I:", I)

    X = integrate.trapezoid(colorfunc.xbar*I, colorfunc.wavelength)
    Y = integrate.trapezoid(colorfunc.ybar*I, colorfunc.wavelength)
    Z = integrate.trapezoid(colorfunc.zbar*I, colorfunc.wavelength)


    return [X,Y,Z]

# tristimulus equation for multiple birefringent values
def tristimulus_values2(theta, phi, biref, z, E0):
    I = E0*transmittance2(theta,phi,biref,z,colorfunc.wavelength)
    # print(np.size(colorfunc.xbar), np.size(I), np.size(colorfunc.xbar*I))
    # print("I:", I)

    X = integrate.trapezoid(colorfunc.xbar*I, colorfunc.wavelength)
    Y = integrate.trapezoid(colorfunc.ybar*I, colorfunc.wavelength)
    Z = integrate.trapezoid(colorfunc.zbar*I, colorfunc.wavelength)


    return [X,Y,Z]

MXR = [[0.029673594112471013, -0.015197482868037232, \
-0.004147700183985282], [-0.00884098526345552,
     0.015660617855301054, -0.0001892101113823349], \
[0.0015087105299084586, -0.0031757126953903037,
     0.008643192548569953]]
                         
MXR_arr = np.array(MXR)*[123, 135, 144]/107

MXR = MXR_arr.tolist()

def XYZtoRGB2(X,Y,Z):
    assert X > 0 and Y > 0 and Z > 0
    MXRArray = np.array(MXR)

    sumXYZ = X+Y+Z
    x=X/sumXYZ
    y=Y/sumXYZ
    z=Z/sumXYZ

    assert x > 0 and y > 0 and z > 0 and x < 1 and y < 1 and z < 1
    rgb = np.dot(MXRArray, np.array([X,Y,Z]))


    for i in range(len(rgb)):
        if rgb[i] > 1:
            rgb[i] = 1

        if rgb[i] < 0:
            rgb[i] = 0

    return rgb

def plotcolors():
    # df = pandas.read_csv('ciexyz31_1.csv',header=0,names=['wavelength','xbar','ybar','zbar'])

    # lb = df.wavelength <= 780
    # ub = df.wavelength >= 380

    # colorfunc = df[lb & ub]

    res=tristimulus_values(theta,phi,biref,z,E0)

    X = res[0]
    Y = res[1]
    Z = res[2]
    color2 = XYZtoRGB2(X, Y, Z)


    axis_color = "yellow"
    fig2 = plt.figure()
    ax = fig2.add_subplot(111)

    # Adjust the subplots region to leave some space for the slider
    fig2.subplots_adjust(bottom=0.25)

    x=[0,0,2,2,0]
    y=[0,2,2,0,0]
    ax.fill(x,y,facecolor=tuple(color2))

    z_slider_ax = fig2.add_axes([0.15, 0.15, 0.65, 0.03], facecolor=axis_color)
    z_slider = Slider(z_slider_ax, 'Thickness (nm)', 0, .6e6, valinit=z)

    def update(val):
        newz = z_slider.val
        X,Y,Z = tristimulus_values(theta,phi,biref,newz,E0)
        newcolor = XYZtoRGB2(X,Y,Z)
        ax.fill(x,y,facecolor=tuple(newcolor))
        fig2.canvas.draw_idle()

    z_slider.on_changed(update)

    plt.show()

# plotcolors()
