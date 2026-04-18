## MODIFIED Requirements

### Requirement: Automation remains operationally controllable
Beets execution SHALL support operator-controlled manual rescue processing after SoulSync cutover, and beets-inbox SHALL NOT remain the default primary automated ingest/promotion backend.

#### Scenario: Operator executes manual rescue run
- **WHEN** beets runner is invoked manually against an approved rescue boundary
- **THEN** processing occurs within declared boundary checks and logs are emitted to state paths
- **AND** this execution is fallback-oriented rather than the canonical default ingest path
