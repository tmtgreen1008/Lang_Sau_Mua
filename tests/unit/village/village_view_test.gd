extends GdUnitTestSuite
## Unit tests for VillageView.sync (src/gameplay/village/village_view.gd, ADR-0002 rule 7): show
## the progress' current state at once, with no effect. The view sits in the tree because its
## effects use tweens. Pieces come from DataFixtures: house_1 at 1 request, house_2 at 3; levels
## at 0, 2 and 4 requests.

var _progress: VillageProgress
var _view: VillageView


func before_test() -> void:
	_progress = VillageProgress.new()
	_progress.configure(DataFixtures.village(), DataResult.new())
	_view = auto_free(VillageView.new())
	add_child(_view)
	_view.setup(_progress)


func test_sync_shows_the_restored_pieces_without_an_effect() -> void:
	# Arrange: the progress changed silently (a save was loaded).
	_progress.from_dict({"completed_requests": 3})

	# Act
	_view.sync()

	# Assert
	assert_float(_view._blend["house_1"]).is_equal(1.0)
	assert_float(_view._blend["house_2"]).is_equal(1.0)
	assert_bool(_view._tweens.is_empty()).is_true()


func test_sync_hides_pieces_that_are_not_restored_yet() -> void:
	# Arrange
	_progress.from_dict({"completed_requests": 1})

	# Act
	_view.sync()

	# Assert
	assert_float(_view._blend["house_1"]).is_equal(1.0)
	assert_float(_view._blend["house_2"]).is_equal(0.0)


func test_sync_cancels_a_running_effect_and_shows_the_final_state() -> void:
	# Arrange: a hand-over starts the restore effect of house_1.
	_progress.on_request_completed(1)
	var effect_started: bool = not _view._tweens.is_empty()

	# Act
	_view.sync()

	# Assert
	assert_bool(effect_started).is_true()
	assert_bool(_view._tweens.is_empty()).is_true()
	assert_float(_view._blend["house_1"]).is_equal(1.0)


func test_sync_takes_the_ground_tint_of_the_current_level() -> void:
	# Arrange: two requests done is level 2, tinted #d8b86020.
	_progress.from_dict({"completed_requests": 2})

	# Act
	_view.sync()

	# Assert
	assert_bool(_view._tint_to.is_equal_approx(Color("#d8b86020"))).is_true()


func test_the_old_name_is_gone() -> void:
	# Arrange / Act / Assert: one contract name for every view.
	assert_bool(_view.has_method("sync_instant")).is_false()
