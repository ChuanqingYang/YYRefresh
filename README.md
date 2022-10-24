# YYRefresh

A Custom Pull_To_Refresh Widget Code by `SwiftUI`.

THANKS To [kavsoft](https://www.youtube.com/watch?v=5rD5GhYVBPg)

# Preview

![](https://github.com/ChuanqingYang/YYRefresh/blob/main/refresh.gif)

# Usage
 
1.SPM `https://github.com/ChuanqingYang/YYRefresh.git`

2.Sample Code Below

``` swift

YYRefresh(config: .init()) {
    // Your View Which Need To Refresh
    VStack {
        Text("Hello World~")
    }
  } onRefrsh: {
    // Async Method to fetch data from server or somewhere
    try? await Task.sleep(for: .seconds(2))
  }

```

