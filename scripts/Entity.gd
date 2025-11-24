extends CharacterBody3D
class_name Entity

var health: int = 100
var max_health: int = 100

func take_damage(damage: int):
	if health <= 0:
		return 
	health -= damage
	print("remaining health: ", health)

	if health <= 0:
		health = 0
		die() 
	else: 
		hurt()
		
func die():
	push_error("UNIMPLEMENTED ERROR: NetworkAdaptor.send_ping()")
	
func hurt():
	push_error("UNIMPLEMENTED ERROR: NetworkAdaptor.send_ping()")
