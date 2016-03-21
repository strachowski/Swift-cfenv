# Swift-cfenv

WORK IN PROGRESS!!!! Please ignore for now, not ready for consumption just yet!!!!!

The Swift-cfenv package will provide classes and methods to parse Cloud Foundry-provided environment variables, such as port number, host name/ip address, and URL of the application. It also provides useful default values when running the application locally.

The package determines if you are running "locally" versus running on the cloud (i.e. Cloud Foundry app), based on whether the VCAP_APPLICATION environment variable is set. If not set, it is assumed you are running in "local" mode instead of "cloud mode".

As reference, see https://www.npmjs.com/package/cfenv.
