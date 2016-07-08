# ixa-pipes-dockerize  #

ixa-pipes-dockerize helps creating docker images that contain the ixa-pipe
toolset, or a selected subset of it. In order to create the docker images,
you will need to compile each of the ixa-pipe tool you want to insert, and
copy the resulting jarfiles and the appropriate models, 

## Pre-requisites ##

You need the jar files of the ixa-pipe components you want to
include. Please follow the instructions at the
[ixa-pipes webpage](http://ixa2.si.ehu.es/ixa-pipes/) for compiling the
ixa-pipe tools, and also to obtain the required models.

Obviously, dockers have to be installed in your computer. Refer to
[docker website](https://www.docker.com/) this document

## Configuration file ##

All the required information is described in a configuration file
(`config.json`), which contains information of each of the ixa-pipe tools,
including the location of the jar files, models and command-line switches.

The general structure of the config file is the following:

```json
{
  "lang" : "en",
  "pipes" : {
    "tok" : { ... },
    "pos" : { ... },
    "nerc" : { ... }
  },
  "pipeline" : [
    "tok", "pos", "nerc"
  ]
}
```

`lang` describes the language. `pipes` contains one element for each of the
ixa-pipe tool (see below). Finally, the `pipelne` field specifies the
particular tools (and the order) that are to be included into the docker
image.

### Describing the tools ###

Each tool is described using three fields:

- `jar`: the location of the jarfile in the host machine.
- `cli-opt': the command line option required by the tool. This field can
  contain the variable `lang`, which will take the value of the 'lang' field
  in the configuration file.
- `models`: a list of model files used by the tool. Each model comes with
  two sub-fields that describe the location of the model file, and the
  command line option.

For instance, the description of the `ixa-pipe-nerc` tool is the following:

```javascript
{
  "pipes" : {
   "nerc" : {
     "jar" : "jar/ixa-pipe-nerc-1.6.0-exec.jar",
     "cli-opt" : "tag",
     "models" : [
       {
         "file" : "model/en-local-conll03.bin",
         "cli-opt" : "-m"
       }
     ]
   }
  }
}
```

This definition would correspond to the following command when calling the tool:
```
java -jar jar/ixa-pipe-nerc-1.6.0-exec.jar tag -m model/en-local-conll03.bin
```

## Creating the docker image ##

Run the following command to create the `Dockerfile` according to the
configuration file:

```
perl dockerize.pl
```

The script will create two files, 'Dockerfile` and `docker_autorun.sh`,
required to create the image.

Then, build the image directly, for instance, 
```
docker built -t tok-pos-nerc .
```

You are now ready to run the toolchain into a docker container:

```
cat file.txt | docker run -i tok-pos-nerc
```

# Contact information #

````shell
Aitor Soroa
IXA NLP Group
University of the Basque Country (UPV/EHU)
E-20018 Donostia-San Sebastián
a.soroa@ehu.eus
````
