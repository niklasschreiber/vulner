@RestController
class GreetingsRestController {

 @GetMapping("/hi")
 def hi(){
  "Hello, world" 
 }
}