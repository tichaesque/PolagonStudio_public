
# PolagonStudio

Design tool for 

> *Polagons: Designing and Fabricating Polarized Light Mosaics with User-Defined Color Changing Behaviors*. Ticha Sethapakdi, Laura Huang, Vivian Chan, Lung-Pan Cheng, Fernando Fuzinatto Dall'Agnol, Stefanie Mueller. 

The Processing interface takes input SVG file(s) and converts them into laser cuttable polarized light mosaics made from cellophane. Please refer to the [paper](https://hcie.csail.mit.edu/research/polagons/polagons.html) for more details.

# Requirements
This code requires the following Python3 libraries:
- numpy
- scipy
- pandas
- flask
- matplotlib
- cairosvg

# Running/using the code
1. `cd PolagonStudio/backend`
2. Run the Polagon backend script: `python3 polagon_service.py`
3. Open Processing. Make sure you have the `ControlP5` Processing library installed
4. Run the Processing code. Save all SVGs to the `data/` folder in the Processing sketch. Fabrication-ready files are saved to `data/cut/`