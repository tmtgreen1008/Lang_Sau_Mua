extends GdUnitTestSuite
## Unit tests for FarmView's tile size (src/gameplay/farming/farm_view.gd): it comes from
## GameConfig through setup(), not from a constant (ADR-0003 rule 8). DataFixtures gives tiles
## of 64 pixels and a 6 by 3 field.

var _view: FarmView


func before_test() -> void:
	var db := CropDatabase.new()
	db.configure(DataFixtures.crops(), DataResult.new())
	var config: GameConfig = DataFixtures.make_game_config()
	var grid := FarmGrid.new(db, config.field_columns(), config.field_rows())
	_view = auto_free(FarmView.new())
	_view.position = Vector2(100.0, 50.0)
	_view.setup(grid, db, config)


func test_setup_takes_the_tile_size_from_the_config() -> void:
	# Arrange / Act / Assert
	assert_float(_view.tile_size).is_equal(64.0)


func test_cell_at_uses_the_configured_tile_size() -> void:
	# Arrange / Act / Assert: x 70 pixels into the field is the second 64-pixel column.
	assert_vector(_view.cell_at(Vector2(170.0, 60.0))).is_equal(Vector2i(1, 0))
	assert_vector(_view.cell_at(Vector2(100.0 + 63.0, 50.0))).is_equal(Vector2i(0, 0))


func test_cell_at_outside_the_field_is_invalid() -> void:
	# Arrange / Act / Assert
	assert_vector(_view.cell_at(Vector2(100.0 + 6 * 64.0 + 1.0, 60.0))).is_equal(FarmView.INVALID_CELL)
	assert_vector(_view.cell_at(Vector2(100.0 - 1.0, 60.0))).is_equal(FarmView.INVALID_CELL)


func test_cell_center_uses_the_configured_tile_size() -> void:
	# Arrange / Act / Assert
	assert_vector(_view.cell_center(Vector2i(1, 0))).is_equal(Vector2(100.0 + 96.0, 50.0 + 32.0))
