-- NOTES TO OTHER DEVS:
-- Always use SingleSync, no matter what.
-- Events should only ever be listened to from one place inside a queue.
opt casing = "snake_case"
opt server_output = "shared/zap/zap_server.luau"
opt client_output = "shared/zap/zap_client.luau"
opt write_checks = false
opt manual_event_loop = true

-- Defined Types
type void = struct {} -- no existing alternative as of now

-- Remotes

-- * Client
event player_ready = {
	from: Client,
	type: Reliable,
	call: SingleSync,
	data: void
}

-- * Server

event general_replication = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: struct {
		ids: u32[],
		values: unknown[],
		removing: u32[],
		ctype: u8
	}
}

event despawn_entity = {
	from: Server,
	type: Reliable,
	call: SingleSync,
	data: u32[]
}

