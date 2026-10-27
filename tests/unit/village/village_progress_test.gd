extends GdUnitTestSuite
## Unit tests for VillageProgress.on_request_completed (src/gameplay/village/village_progress.gd,
## ADR-0002 rule 6). The village no longer knows the neighbor book: Main tells it how many
## requests are done. Pieces and levels come from DataFixtures: pieces at 1 and 3 requests,
## levels at 0, 2 and 4.


func test_one_completed_request_restores_the_first_piece_only() -> void:
	# Arrange
	var village: VillageProgress = _make_village()
	var events: Array[String] = _record(village)

	# Act
	village.on_request_completed(1)

	# Assert
	assert_array(events).is_equal(["piece:house_1"])
	assert_int(village.get_completed_count()).is_equal(1)
	assert_int(village.get_level()).is_equal(1)


func test_crossing_a_level_threshold_emits_level_changed_after_the_pieces() -> void:
	# Arrange
	var village: VillageProgress = _make_village()
	village.on_request_completed(1)
	var events: Array[String] = _record(village)

	# Act
	village.on_request_completed(2)

	# Assert
	assert_array(events).is_equal(["level:2"])
	assert_int(village.get_level()).is_equal(2)


func test_a_jump_restores_every_piece_in_data_order_then_changes_the_level() -> void:
	# Arrange
	var village: VillageProgress = _make_village()
	var events: Array[String] = _record(village)

	# Act
	village.on_request_completed(4)

	# Assert
	assert_array(events).is_equal(["piece:house_1", "piece:house_2", "level:3"])


func test_the_same_count_again_emits_nothing() -> void:
	# Arrange
	var village: VillageProgress = _make_village()
	village.on_request_completed(2)
	var events: Array[String] = _record(village)

	# Act
	village.on_request_completed(2)

	# Assert
	assert_array(events).is_empty()
	assert_int(village.get_completed_count()).is_equal(2)


func test_a_lower_count_updates_silently_for_a_new_game() -> void:
	# Arrange
	var village: VillageProgress = _make_village()
	village.on_request_completed(4)
	var events: Array[String] = _record(village)

	# Act
	village.on_request_completed(0)

	# Assert
	assert_array(events).is_empty()
	assert_int(village.get_completed_count()).is_equal(0)
	assert_int(village.get_level()).is_equal(1)


func test_the_village_no_longer_binds_to_the_book() -> void:
	# Arrange / Act / Assert: ADR-0002 rule 6, no domain module holds another.
	assert_bool(VillageProgress.new().has_method("bind_book")).is_false()


# --- helpers -------------------------------------------------------------------------

func _make_village() -> VillageProgress:
	var village := VillageProgress.new()
	var result := DataResult.new()
	village.configure(DataFixtures.village(), result)
	assert_array(result.errors).is_empty()
	return village


## Records every signal as "piece:<id>" or "level:<n>", in emission order.
func _record(village: VillageProgress) -> Array[String]:
	var events: Array[String] = []
	village.piece_restored.connect(func(id: String) -> void: events.append("piece:" + id))
	village.level_changed.connect(func(level: int) -> void: events.append("level:%d" % level))
	return events
