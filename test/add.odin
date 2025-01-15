// test/add.odin
// odin build test -build-mode:dll
package test

@export
add :: proc "c" (a, b: i32) -> i32 {
	return a + b
}
