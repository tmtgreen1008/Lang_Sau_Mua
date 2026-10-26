class_name Market
extends RefCounted
## Village market logic: sells harvested produce from the farm inventory for money.
## Implements story 003 (design/game-brief.md, MVP feature 3). No nodes, no UI.
##
## Usage:
##   var market := Market.new(grid, db)
##   market.money_changed.connect(hud.set_money)
##   market.sell("ngo", 2)

## Emitted after money changed (new total).
signal money_changed(new_money: int)
## Emitted after produce left the inventory.
signal inventory_changed

## Money the player owns. Only ever increases (prices are never negative), so it
## never goes negative.
var money: int = 0

var _grid: FarmGrid
var _db: CropDatabase


func _init(grid: FarmGrid, db: CropDatabase) -> void:
	_grid = grid
	_db = db


## Units of [param crop_id] in the inventory.
func get_owned(crop_id: String) -> int:
	return int(_grid.inventory.get(crop_id, 0))


## Price of one unit, from the crop data file.
func get_unit_price(crop_id: String) -> int:
	return _db.get_sell_price(crop_id)


## Sells up to [param quantity] units of [param crop_id], never more than owned.
## Returns the number of units actually sold; 0 (and nothing changes) when the crop is
## unknown, the quantity is not positive, or none is owned.
func sell(crop_id: String, quantity: int) -> int:
	var sold: int = mini(quantity, get_owned(crop_id))
	if not _db.has_crop(crop_id) or sold <= 0:
		return 0
	_grid.inventory[crop_id] = get_owned(crop_id) - sold
	money += sold * get_unit_price(crop_id)
	inventory_changed.emit()
	money_changed.emit(money)
	return sold
