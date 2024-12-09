@RestController 

class HelloGroovy {
	@RequestMapping("/") 
	String home(){
		System.out.println("Groovy Service");
		"Groovy Service\n" 
	}
}
