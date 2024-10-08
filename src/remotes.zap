
opt server_output = "shared/zap/zap_server.luau"
opt client_output = "shared/zap/zap_client.luau"

opt casing = "snake_case"

event client_ready = {
    from: Client,
    type: Reliable,
    call: ManySync
}

event replicate_world = {
    from: Server,
    type: Reliable,
    call: SingleSync,
    data: struct {
        changes: map {
            [string]: struct {
                added_or_changed: struct {
                    entities: u32[],
                    values: unknown[]
                },
                removed: u32[]
            }
        },
        destroyed: u32[]
    }
}

event udp_replicate_world = {
    from: Server,
    type: Unreliable,
    call: SingleSync,
    data: struct {
        changes: map {
            [string]: struct {
                added_or_changed: struct {
                    entities: u32[],
                    values: unknown[]
                },
                removed: u32[]
            }
        },
        destroyed: u32[]
    }
}
