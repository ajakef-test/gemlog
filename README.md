Installation:

* First, create and activate a conda environment with dependencies (named "gem" in this example). This environment must always be activated when running gem2ms.
```
conda config --add channels conda-forge
conda create -n gem python=3.7.6 numpy obspy pandas matplotlib cython
conda activate gem
```

* Next, install the gemlog python package from github. This will create an executable gem2ms in a folder where it will be recognized.
```
pip install --upgrade https://github.com/ajakef/gemlog/archive/master.zip
```

* Finally, get the syntax to run gem2ms.
```
gem2ms -h # print the help page
```