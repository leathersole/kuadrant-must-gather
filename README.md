# kuadrant-must-gather
A client tool for gathering Kuadrant information in a OpenShift cluster 

Kuadrant must-gather
=================

`Kuadrant must-gather` is a tool built on top of [OpenShift must-gather](https://github.com/openshift/must-gather) that expands its capabilities to gather Kuadrant information.

### Usage
```sh
oc adm must-gather --image=quay.io/leathersole/kuadrant-must-gather:0.0.2
```

The command above will create a local directory with a dump of Kuadrant state. Note that this command will only get data related to Kuadrant part of the OpenShift cluster.

You will get a dump of:
- The Kuadrant Operator namespace (and its children objects)
- All namespaces (and their children objects) that has Kuadrant resources
- All Kuadrant CRD's definitions
- All Kuadrant CRD's objects

In order to get data about other parts of the cluster you should run just `oc adm must-gather` (without passing a custom image). Run `oc adm must-gather -h` to see more options.
