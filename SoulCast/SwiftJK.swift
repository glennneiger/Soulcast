
class SwiftJK {
  
}

func doOnce (taskName:String, task:() -> ()) -> (Bool) {
  if NSUserDefaults.standardUserDefaults().valueForKey("doOnce-" + taskName) == nil {
    task()
    NSUserDefaults.standardUserDefaults().setValue(true, forKey: "doOnce-" + taskName)
    return true
  } else {
    return false
  }
}

func networkRequestManager() -> AFHTTPRequestOperationManager {
  let manager = AFHTTPRequestOperationManager()
  manager.requestSerializer = AFJSONRequestSerializer(writingOptions: NSJSONWritingOptions.PrettyPrinted)
  manager.responseSerializer = AFJSONResponseSerializer(readingOptions: NSJSONReadingOptions.MutableContainers)
  return manager
}

var debugging = true

func printline(string:String) {
  if debugging {
    println(string)
  }
}