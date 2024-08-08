class_name ListingSort
enum SORT_TYPES { SONG_NAME }

static func get_sort_callable(sort_type: SORT_TYPES) -> Callable:
	#match sort_type:
	
	# default to by_title
	return by_title

static func by_title(listing_a: ChartListing, listing_b: ChartListing):
	if listing_a.chart.chart_info["song_title"].nocasecmp_to(listing_b.chart.chart_info["song_title"]) < 0:
		return true
	return false
