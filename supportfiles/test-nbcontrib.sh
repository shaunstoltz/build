#!/bin/bash

RAPIDS_DIR=/rapids
NOTEBOOKS_DIR=${RAPIDS_DIR}/notebooks-contrib
NBTEST=${RAPIDS_DIR}/utils/nbtest.sh

cd $(dirname ${NOTEBOOKS_DIR})
git clone https://github.com/rapidsai/notebooks-contrib.git
cd ${NOTEBOOKS_DIR}
TOPLEVEL_NB_FOLDERS=$(find . -name *.ipynb |cut -d'/' -f2|sort -u)

# Add notebooks that should be skipped here
# (space-separated list of filenames without paths)
#
# louvain_benchmark.ipynb and pagerank_benchmark.ipynb - timedout
# https://gpuci.gpuopenanalytics.com/job/docker/job/tests/job/docker-test-notebooks-contrib/17/CUDA_VERSION=10.0,LINUX_VERSION=ubuntu18.04/consoleFull
# cuml_benchmarks.ipynb - crash/hang on CentOS7 CUDA 10.*
# https://gpuci.gpuopenanalytics.com/job/docker/job/tests/job/docker-test-notebooks-contrib/24

SKIPNBS="louvain_benchmark.ipynb pagerank_benchmark.ipynb cuml_benchmarks.ipynb"

## Check env
env

EXITCODE=0

# Always run nbtest in all TOPLEVEL_NB_FOLDERS, set EXITCODE to failure
# if any run fails
for folder in ${TOPLEVEL_NB_FOLDERS}; do
    echo "========================================"
    echo "FOLDER: ${folder}"
    echo "========================================"
    cd ${NOTEBOOKS_DIR}/${folder}
    for nb in $(find . -name "*.ipynb"); do
        nbBasename=$(basename ${nb})
        # Skip all NBs that use dask (in the code or even in their name)
        if ((echo ${nb}|grep -qi dask) || \
            (grep -q dask ${nb})); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nb} (suspected Dask usage, not currently automatable)"
            echo "--------------------------------------------------------------------------------"
        elif (echo " ${SKIPNBS} " | grep -q " ${nbBasename} "); then
            echo "--------------------------------------------------------------------------------"
            echo "SKIPPING: ${nb} (listed in skip list)"
            echo "--------------------------------------------------------------------------------"
        else
            cd $(dirname ${nb})
            nvidia-smi
            ${NBTEST} ${nbBasename}
            EXITCODE=$((EXITCODE | $?))
            cd ${NOTEBOOKS_DIR}/${folder}
        fi
   done
done

nvidia-smi

exit ${EXITCODE}
