# IMPLEMENTATION_GUIDE.md (brief)
- Keep the kernel dependency-light and text-first.
- Emit events for every syscall and module invoke path.
- Validate descriptors against schema at mount time.
- Enforce capability checks at invoke time; emit `policy:decision`.
- Prefer immutable data structures at boundaries; copy on write.
- Provide deterministic error paths for timeouts and transport failures.
