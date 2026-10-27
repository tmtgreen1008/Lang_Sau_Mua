extends GdUnitTestSuite
## Unit tests for NeighborBook.get_completed_count (src/gameplay/neighbors/neighbor_book.gd): the
## number Main hands to the village (ADR-0002 rule 6). Content is DataFixtures.neighbors().


func test_a_new_book_has_no_completed_requests() -> void:
	# Arrange / Act
	var book: NeighborBook = _make_book()

	# Assert
	assert_int(book.get_completed_count()).is_equal(0)


func test_completing_requests_counts_them_across_neighbors() -> void:
	# Arrange
	var book: NeighborBook = _make_book()
	var inventory: Dictionary = {"ngo": 10}

	# Act
	book.complete_request("ba_tu", inventory)
	book.complete_request("chu_ba", inventory)

	# Assert
	assert_int(book.get_completed_count()).is_equal(2)


func test_the_count_follows_a_restored_save() -> void:
	# Arrange
	var book: NeighborBook = _make_book()

	# Act
	book.from_dict({"request_states": {"ba_tu_1": "done", "ba_tu_2": "done", "chu_ba_1": "done"}})

	# Assert
	assert_int(book.get_completed_count()).is_equal(3)


func test_a_failed_hand_over_does_not_count() -> void:
	# Arrange
	var book: NeighborBook = _make_book()

	# Act
	var request: Dictionary = book.complete_request("ba_tu", {"ngo": 0})

	# Assert
	assert_dict(request).is_empty()
	assert_int(book.get_completed_count()).is_equal(0)


func _make_book() -> NeighborBook:
	var book := NeighborBook.new()
	var result := DataResult.new()
	book.configure(DataFixtures.neighbors(), result)
	assert_array(result.errors).is_empty()
	return book
