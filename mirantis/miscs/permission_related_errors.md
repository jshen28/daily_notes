# PERMISSION RELATED ERRORS

## PIP RELATED

Packages installed by pip with **root** user will not be usable for users who do not
have proper privileges if system umask is not equal to **0022**. For example, if system
defualt umask is **0027** then user falls under **other** category cannot use them.

There are several methods to solve this problems.

### CHANGE PERMISSION MANUALLY

```bash
chmod -R o+r ${PAKCAGE_PATH}
```

### ADD CERTAIN USER TO GROUP STAFF

Pip will by default allow staff group to use managed packages. So another method is to
identify potential user and add them to **staff** group.

```bash
usermod -a -G staff ${USER}
```

### UNINSTALL & CHANGE UMASK & INSTALL AGAIN

Change umask and allow packages to be readable by all the other users. This method might
be unsafe.

```bash
pip uninstall ${PACKAGE}
umask 0022
pip install ${PACKAGE}
```