// test/add.odin
package test

@export
add :: proc "c" (a, b: i32) -> i32 {
	return a + b
}
