#.bashrc
export CONDA_DIR=$HOME/packages/miniconda2 (user define dir)
export PATH=$PATH:$CONDA_DIR/bin
export MAPXDIR=/cluster/projects/nn2993k/sim/packages/mapx/
export BAMGDIR=/cluster/projects/nn2993k/sim/packages/bamg/


wget http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh -O miniconda.sh
chmod u+x miniconda.sh
./miniconda.sh -b -p $CONDA_DIR

wget https://github.com/nansencenter/docker-boost-petsc-gmsh/blob/master/docker-boost-petsc-gmsh-conda/requirements.txt

conda update conda
conda create --name nextsim3 python=3.6
source activate nextsim3
conda install -c conda-forge --file requirements.txt



cd $NEXTSIMTOOLS_ROOT_DIR/python/mapx
python setup.py install

cd $NEXTSIMTOOLS_ROOT_DIR/python/bamg
python setup.py install

#test with import mapx and import bamg
