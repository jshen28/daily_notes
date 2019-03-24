# CVP测试运行及总结

## 背景

CVP测试是在MCP部署完成后进行的一系列的功能和性能测试的总称，包括如下的几个方面的内容

* Sanity Tests
* HA tests
* Funcational Tests
* Performance Tests
* Simplified Performance Tests
* stacklight test

### Sanity Tests

该测试的主要功能是判断集群是否正常安装：包括服务是否正常启动，网络相关参数是否正常的设置，程序包是否正确安装。

### HA Tests

测试集群组件的高可用功能。

### Functional Tests

Openstack集群的冒烟测试，用以测试openstack各组件的API功能是否正常。

### Performance Tests 和 Simplified Performance Tests

集群的性能测试（rally）。

## 准备工作

### PIPELINE

运行测试脚本的时候会要求指定测试脚本的存放位置，这些默认的位置是在reclass中定义的，在离线的环境下会指定`gerrit`作为的默认源(当然也可以使用`apt`节点)。向gerrit中导入项目可以通过jenkins的pipeline进行。这些pipeline大多以`git-mirror-downstream`命名。

### APT 和自定义的git repo

正常情况下，如需对gerrit中的项目进行修改，应该遵守gerrit的标准流程。首先进行用户的注册是公钥的导入，然后在本地的git中导入相应的私钥，进行git-review等操作。

由于MCP平台部署的相关细节也在不断的发生变化，为了防止出现版本问题，MCP在apt节点上也通过nginx部署了版本兼容的git repo。

#### 使用nginx部署git repo

```bash
git init ${REPO_NAME} --bare && chmod o+r ${REPO_NAME}
cd ${REPO_NAME} && git update-server-info

# update contents
git clone file://${REPO_PATH}

# do updates and push to upstream

# update server info and change permission accordingly
cd ${REPO_PATH} && git update-server-info && chmod o+r ${REPO_PATH}

# then test with clone
git clone http://${IP}:${PORT}/${REPO_NAME}
```

## 测试

### 运行SANITY TEST

由于安装了一些软件导致各节点之间不统一，可以忽略。

### 运行HA Tests

未成功运行

### 运行Functional Tests

大部分的失败原因为环境没有安装对象存储相关的后端引发的。

### 运行Performance Test

由于SPT是PT的子集，故只执行了PT。执行不成功。原因是环境中已经设置了很多的network等资源，但是rally配置文件没有支持这种情况，造成rally运行报错。所以这个测试需要运行在一个比较干净的环境中，以防干扰。

PT对镜像、flavor和网络有命名的要求，要求镜像名称为Ubuntu，网络名称为floating，flavor名称为m1.medium。名称不存在，pipeline无法正常的执行。

## 问题记录

1. pipeline-libary中的Validate.groovy中的rally测试相关的部分和rally:0.11.1的镜像的默认路径不兼容。主要原因是rally镜像的默认workdir发生了变化，而groovy脚本中依然默认路径为`/home/rally`(正确的值为`/home/rally/source`)
2. gerrit不要通过https访问，脚本中没有禁用ssl证书的校验，会引发错误。
3. 执行测试的是后返现从gerrit clone失败，原因是repo没有初始化。方便起见，直接手动在gerit中创建空项目即可，然后运行相关的pipeline即可设置好。
4. 在执行functional测试的是后，发现cvp/tempest项目没有18.0.0这个分支。登陆南方节点，发现这个分支当时是存在的，应该源没有更新导致的。解决的方法是手动创建了tag的分支，并推到git库中。
5. apt节点的cvp-configuration比较旧，没有*skip-list-queens.yaml*，可以使用github中的官方源或手动更新apt上的仓库。
6. *stacklight*测试requirements中缺少salt，修改项目，增加**salt==2017.7.7**后解决了问题。
7. *staclight*测试，*alerta*的版本不能超过*6.0.0*，这是因为高版本代码不支持python2.7。