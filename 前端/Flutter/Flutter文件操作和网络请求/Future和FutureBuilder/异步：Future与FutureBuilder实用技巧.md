https://coding.imooc.com/learn/questiondetail/134645.html

https://app.yinxiang.com/shard/s35/nl/9757212/41cc6bf9-c42b-4852-adca-63c5b29d3a3e

Future是dart:async包中的一个类，使用它时需要导入dart:async包，Future有两种状态：

借助Future我们可以在Flutter实现异步操作

Future是异步的，如果我们要将异步转同步，那么可以借助async await来完成。

future.whenComplete就是Future的finally。

设置一个超时时间future.timeout

### Future的两种使用方法
1、使用then
```DART
    HomeDao.fetch().then((value){
      setState(() {
        resultString = json.encode(value);
      });
    }).catchError((e){
      resultString = e.toString();
    });
```

2、使用async 和 await
```DART

```

https://github.com/npm-ued/flutter_trip