# PRYIII---GCD

This is the repository designed to address the code based on the thesis on the project "City simulations on extraordinary circumstances".
One can distinguish two folders inside the leading directory: "GAMA Model" and "PYTHON Model".

## GAMA Model
This folder contains information about the GAMA Model we have developed -to be able to deploy the models the user will need to download the GAMA model [https://gama-platform.org/](https://gama-platform.org/download/). It features two directories.
The folder "Includes" contains the required shapefiles to deploy the model. Meanwhile, the repository "Models" holds the three GAMA files used to develop the evacuation model.
The file "ValenciaModel.gaml" contains the code required to obtain a simulation of any city.
"Evacuation.gaml" is the file used when implementing the evacuation model.
Finally, the file "Experimento_controlado.gaml" features the evaluation of the two other models, i.e., it contains the model simulation for a single person agent, their path to their work, and the time required by that agent to go over this path.

## PYTHON Model
The directory "PYTHON Model" contains all the code regarding the simulation using the Python language. Inside this repository, one can find two folders and two files. Both folders contain the needed files for the Python Model. Meanwhile, the CSV file holds the information on the edge weights. Finally, the file "Python Model.ipynb" is a notebook that contains the entirety of the Python Model.
