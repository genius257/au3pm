---
excerpt: Restart a package
---
# Restart
Restart a package

### Synopsis

```
au3pm restart
```

### Description

This restarts a package.

This runs a package’s “stop”, “restart”, and “start” scripts, and associated pre- and post- scripts, in the order given below:


1. prerestart
2. prestop
3. stop
4. poststop
5. restart
6. prestart
7. start
8. poststart
9. postrestart

### Note

Note that the “restart” script is run __in addition__ to the “stop” and “start” scripts, not instead of them.
