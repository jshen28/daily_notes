# 2018/01/09

## CONFIGURE JAVA CIPHER

[See this](https://stackoverflow.com/questions/19462675/des-encryption-plain-vs-cipher-length) for a introduction.
[See this](https://stackoverflow.com/questions/10935068/what-are-the-cipher-padding-strings-in-java) for a comprehensive list of possible implementations. But fully understanding requires cryptography knowledge.

```java
/*
    Algorithm/Mode/Padding
    It looks like default implementation is DES/ECB/PKCS5Padding
*/
String instanceType = "DES/ECB/NoPadding";
Cipher.getInstace(instanceType);
```

## CRYPTOGRAPHY TERMS

### Plaintext/Ciphertext

### Algorithms

### Mode Of Operation

### Padding

[Check this for a detailed description of DES](https://en.wikipedia.org/wiki/Block_cipher_mode_of_operation)

## JAVA KEYSTORE & TRUSTSTORE

There are quite a few different formats of certificate and private key file out there. A good starting point for me is [this post](https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them).

In order to enable SSL/TLS with tomcat, it is necessary to generate at least a keystore file. In case client auth is prefered, truststore and client-side keystore file are also necessary.

### GENERATE KEYSTORE FILE

[copy from this link](http://www.maximporges.com/2009/11/18/configuring-tomcat-ssl-clientserver-authentication/)

```bash
keytool -genkeypair -keyalg RSA -dname $dname -keypass $password -keystore server.jks -storepass $password

# ALIAS IS USED TO EXPORT CERTIFICATE TO TRUSTSTORE
keytool -genkeypair -alias clientkey -keyalg RSA -dname $dname -keypass $pass -storepass $pass -keystore client.jks
```

### GENERATE TRUSTORE FILE

```sh
# OUTPUT CLIENT CERTIFICATE FROM JKS FILE
keytool -exportcert -alias clientkey -file client-public.cer -keystore client.jks -storepass $pass

# IMPORT CLIENT CERTIFICATE INTO SERVER JKS FILE
keytool -importcert -keystore server.jks -alias clientcert -file client-public.cer -storepass $pass -noprompt
```

### GENERATE PKCS#12 FILE

In order to install client private & public key on windows, a PKCS#12 format file should be used. [Thanks to this post](https://security.stackexchange.com/questions/3779/how-can-i-export-my-private-key-from-a-java-keytool-keystore), one can easily export those from given JKS format keystore file.

```sh
# GENERATE A PKCS#12 FILE USING KEYTOOL
# AVALIABLE SINCE JAVA 6
keytool -importkeystore -srckeystore $client -destkeystore $pfx -deststoretype "PKCS12"
```

### CONFIGURE TOMCAT SERVER.XML

For completeness, sample server.xml configuration is listed below, attribute **keystoreType** must be configured if non-JKS format keystore is preferred. But I high doubt feasiblity of configuring TLS for tomcat since it will be much easier enabling it on the load balancer. For example, configure ELB for Elastic Beanstalk could achieve HTTPS without further configuring tomcat on the backend.

```xml
<Connector port="8443"
           protocol="org.apache.coyote.http11.Http11Protocol"
           maxThreads="150" SSLEnabled="true" scheme="https" secure="true"
           keystoreFile="/path/to/keystore"
           keystorePass="password"
           keystoreType="JKS/PKCS12"
           truststoreFile="/path/to/truststore"
           truststorePass="password"
           truststoreType="jKS/PKCS12"
           clientAuth="true" sslProtocol="TLS"
/>
```
