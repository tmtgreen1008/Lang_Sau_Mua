extends GdUnitTestSuite
## Unit tests for Player (src/gameplay/player/player.gd): speed and radius come from GameConfig
## through setup(), not from constants (ADR-0003 rule 8). DataFixtures gives speed 300, radius 12.5.


func test_setup_takes_speed_and_radius_from_the_config() -> void:
	# Arrange
	var player: Player = auto_free(Player.new())

	# Act
	player.setup(DataFixtures.make_game_config())

	# Assert
	assert_float(player.speed).is_equal(300.0)
	assert_float(player.radius).is_equal(12.5)


func test_the_player_walks_speed_pixels_per_second() -> void:
	# Arrange
	var player: Player = auto_free(Player.new())
	player.setup(DataFixtures.make_game_config())
	player.position = Vector2.ZERO
	player.move_to(Vector2(1000.0, 0.0))

	# Act
	player._process(0.5)

	# Assert
	assert_float(player.position.x).is_equal_approx(150.0, 0.001)


func test_the_player_emits_arrived_once_on_reaching_the_target() -> void:
	# Arrange
	var player: Player = auto_free(Player.new())
	player.setup(DataFixtures.make_game_config())
	player.position = Vector2.ZERO
	var arrivals: Array[int] = []
	player.arrived.connect(func() -> void: arrivals.append(1))
	player.move_to(Vector2(10.0, 0.0))

	# Act
	player._process(1.0)
	player._process(1.0)

	# Assert
	assert_int(arrivals.size()).is_equal(1)
	assert_vector(player.position).is_equal(Vector2(10.0, 0.0))


func test_before_setup_the_player_does_not_move() -> void:
	# Arrange: speed 0 makes a forgotten setup obvious instead of hiding it behind a default.
	var player: Player = auto_free(Player.new())
	player.position = Vector2.ZERO
	player.move_to(Vector2(100.0, 0.0))

	# Act
	player._process(1.0)

	# Assert
	assert_vector(player.position).is_equal(Vector2.ZERO)
