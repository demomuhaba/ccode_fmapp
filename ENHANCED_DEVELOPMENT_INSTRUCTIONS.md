# Enhanced Claude Development Instructions

## Core Development Philosophy
- **Zero Hallucination**: Always verify facts, check existing code, and validate assumptions
- **Production Ready**: Every output must be deployment-ready with proper error handling
- **Complete Solutions**: Deliver fully functional, tested, and documented solutions

## Success Criteria Framework

### 1. Define Success Before Starting
- **Functional Requirements**: What the app must do
- **Non-Functional Requirements**: Performance, security, scalability
- **Acceptance Criteria**: Specific, measurable outcomes
- **Definition of Done**: Code works, tests pass, documentation exists

### 2. Smart Planning & Execution

#### Initial Planning Phase
```
1. Analyze requirements thoroughly
2. Identify all dependencies and constraints  
3. Break down into atomic, testable tasks
4. Estimate complexity and risks
5. Plan verification strategy
```

#### Adaptive Reconstruction
- **Continuous Assessment**: Re-evaluate progress after each task
- **Dynamic Replanning**: Adjust approach based on discoveries
- **Risk Mitigation**: Identify and address blockers early
- **Quality Gates**: Don't proceed until current phase is solid

## Progress Tracking System

### Required Project Files
Always maintain these files and update them with every significant change:

#### project_status.md
```markdown
# Project Status

## Current Phase
[Development/Testing/Deployment/Complete]

## Completed Tasks
- [x] Task 1 - Description
- [x] Task 2 - Description

## In Progress
- [ ] Current task details
- [ ] Next immediate task

## Blocked/Issues
- Issue description and resolution plan

## Success Metrics
- Metric 1: Status
- Metric 2: Status

## Next Steps
1. Immediate next action
2. Following action
3. Verification plan
```

#### changelog.md
```markdown
# Changelog

## [Date] - Version/Phase
### Added
- New features implemented

### Changed  
- Modified functionality

### Fixed
- Bug fixes and corrections

### Verified
- Tests passed
- Functionality confirmed
```

### Progress Tracking Protocol
1. **Before Starting**: Read project_status.md and changelog.md
2. **During Work**: Update status for each completed task
3. **After Sessions**: Update both files with current state
4. **Verification**: Cross-reference with actual code files

## MCP Server Auto-Identification

### Automatic MCP Detection
```python
# Always run this detection sequence:
1. Scan for mcp-server configuration files
2. Identify available MCP servers and capabilities
3. Determine optimal server for each task type
4. Auto-configure and start required servers
5. Handle server errors and fallbacks
```

### MCP Usage Decision Matrix
- **Database Operations**: Use database MCP if available
- **File Operations**: Use filesystem MCP for complex operations
- **API Integrations**: Use relevant API MCP servers
- **Testing**: Use testing framework MCP servers
- **Deployment**: Use deployment MCP servers

### MCP Server Startup Protocol
```bash
# Always execute on project start:
1. Check MCP server status
2. Start required servers
3. Verify connectivity
4. Fix any startup errors
5. Log server status in project_status.md
```

## Compilation, Testing & Verification Framework

### Pre-Development Verification
1. **Environment Check**: Verify all dependencies
2. **Tool Availability**: Confirm build tools, compilers, test frameworks
3. **Configuration Validation**: Check all config files

### Development Phase Verification
1. **Incremental Compilation**: Compile after each significant change
2. **Unit Testing**: Write and run tests for each component
3. **Integration Testing**: Test component interactions
4. **Static Analysis**: Run linters, type checkers, security scanners

### Post-Development Verification
1. **Full Build**: Complete compilation from scratch
2. **Test Suite**: Run all tests (unit, integration, e2e)
3. **Performance Testing**: Verify performance requirements
4. **Security Scan**: Check for vulnerabilities
5. **Documentation**: Verify all documentation is current

### Verification Commands (Auto-detect and run)
```bash
# Language-specific verification commands:
# JavaScript/Node.js:
npm install && npm run build && npm test && npm run lint

# Python:
pip install -r requirements.txt && python -m pytest && flake8 && mypy

# Java:
mvn clean install && mvn test && mvn checkstyle:check

# Go:
go mod tidy && go build && go test ./... && go vet

# Rust:
cargo build && cargo test && cargo clippy

# Always adapt to project-specific commands
```

## Error Prevention & Recovery

### Error Prevention
1. **Validate Early**: Check inputs and assumptions immediately
2. **Defensive Coding**: Handle edge cases and errors gracefully
3. **Code Reviews**: Self-review all code before committing
4. **Documentation**: Comment complex logic and decisions

### Error Recovery Protocol
1. **Immediate Diagnosis**: Identify root cause, not just symptoms
2. **Rollback Strategy**: Always have a working state to return to
3. **Fix Verification**: Ensure fix doesn't introduce new issues
4. **Post-Fix Testing**: Re-run full test suite

## Quality Assurance Checklist

### Code Quality
- [ ] Follows project coding standards
- [ ] Proper error handling implemented
- [ ] Security best practices followed
- [ ] Performance optimized
- [ ] Memory leaks prevented
- [ ] Logging and monitoring included

### Testing Quality
- [ ] Unit tests cover all functions
- [ ] Integration tests verify workflows
- [ ] Edge cases tested
- [ ] Error conditions tested
- [ ] Performance benchmarks met

### Documentation Quality
- [ ] Code is self-documenting
- [ ] API documentation complete
- [ ] Setup instructions clear
- [ ] Architecture documented
- [ ] Troubleshooting guide included

## Continuous Improvement Protocol

### After Each Session
1. **Retrospective**: What worked well? What didn't?
2. **Lessons Learned**: Document insights for future reference
3. **Process Updates**: Refine approach based on experience
4. **Knowledge Base**: Update project documentation

### Before Each Session
1. **Context Recovery**: Read project_status.md and changelog.md
2. **Code Review**: Quickly scan recent changes
3. **Environment Check**: Verify development environment
4. **Goal Setting**: Define specific objectives for session

## Implementation Protocol

### Session Startup Sequence
1. Load and review CLAUDE.md
2. Read project_status.md and changelog.md
3. Start and verify MCP servers
4. Scan project structure and recent changes
5. Define session objectives
6. Plan immediate tasks

### Session Work Flow
1. Execute planned tasks incrementally
2. Verify each step before proceeding
3. Update progress tracking continuously
4. Handle errors immediately
5. Test functionality continuously

### Session Completion Sequence
1. Run full verification suite
2. Update project_status.md
3. Update changelog.md
4. Commit changes (if requested)
5. Document any issues or next steps

This framework ensures every development session produces high-quality, production-ready code with full traceability and verification.