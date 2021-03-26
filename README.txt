
Provide a containerised environment for ssh users.

We typically have issues with users on our interactive pool such that one user may consume all of the resources on the login host and cause issues for other users on the system. At the same time, we want users to be able to launch straight into their environment; whether its a containerised image with the software want already installed or if the user wants an entirely different OS.

At the same time, we may also want to restrict which file system mounts and/or even hosts that the user is allowed to access, but not have to provide them a long list of if/else statements to manaully determine where to ssh to.

Finally, we would also like to provide users some persistence to their sessions, such that unreliable network connections would not terminate their sessions.

We spawn for each person ssh's in a new pod that persists. If they ssh after, they will reach the same pod.

The pod will provide limits on the resources they can access: these include
- cpu and memory limits as imposed by the container
- specific bind mounts either through PVCs or hostPath mounts

questions:
- how about uid and gid mappings? how should we inject them? require ldap lookup? or get sssd to provide it? or static mappings only?
- honour secondary gid groups for file access
- allow users to specify the environment they want (ie os')
- how to extend that to the users jobs on the cluster?
- x11 environments?
- provide means for local system bootstraps, eg create home directories, impose quotas, etc.
- host keys? so users don't get alerts for local MITM attacks?

 
