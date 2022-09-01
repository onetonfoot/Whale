FROM julia:latest
# install gcc which is needed for PackageCompiler
RUN apt update && apt install build-essential -y
# the correct path depends on the docker build context
ADD . /opt/MyPkg
RUN julia -e 'import Pkg; Pkg.add(url="https://github.com/onetonfoot/Whale.git"); Pkg.develop(path="/opt/MyPkg")'
RUN julia -e 'using Whale, MyPkg; Whale.sysimage(MyPkg)'
# this causes the project to be instantiated
# RUN julia -J $HOME/.julia/sysimages/MyPkg.so #            --project=/opt/MyPkg #            -e 'using MyPkg'
ENTRYPOINT julia -J $HOME/.julia/sysimages/MyPkg.so --project=/opt/MyPkg 
