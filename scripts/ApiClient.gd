extends Node

signal response_received(tag: String, data: Dictionary)
signal request_failed(tag: String, status_code: int, message: String)

const DEFAULT_BASE_URL := "http://127.0.0.1:8765"

var base_url := DEFAULT_BASE_URL


func _ready() -> void:
	base_url = ProjectSettings.get_setting("application/config/ai_service_url", DEFAULT_BASE_URL)


func get_json(path: String, tag: String) -> void:
	_request_json(HTTPClient.METHOD_GET, path, {}, tag)


func post_json(path: String, payload: Dictionary, tag: String) -> void:
	_request_json(HTTPClient.METHOD_POST, path, payload, tag)


func _request_json(method: int, path: String, payload: Dictionary, tag: String) -> void:
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_request_completed.bind(request, tag))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := ""
	if method != HTTPClient.METHOD_GET:
		body = JSON.stringify(payload)
	var error := request.request(base_url + path, headers, method, body)
	if error != OK:
		request.queue_free()
		request_failed.emit(tag, 0, "request error %s" % error)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, request: HTTPRequest, tag: String) -> void:
	var text := body.get_string_from_utf8()
	request.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		request_failed.emit(tag, response_code, text)
		return
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		request_failed.emit(tag, response_code, "invalid json: %s" % text)
		return
	response_received.emit(tag, parsed as Dictionary)
