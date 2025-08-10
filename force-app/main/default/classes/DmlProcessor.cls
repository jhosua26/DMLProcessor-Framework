/**
 * DmlProcessor - A modern utility class for handling DML operations with advanced features
 * 
 * This class uses composition to delegate responsibilities to smaller, focused classes:
 * - DmlOperationExecutor: Handles core DML operations
 * - DmlHookManager: Manages hooks and callbacks
 * - DmlContext: Manages execution context and logging
 * - DmlChunker: Handles chunking of large datasets
 * 
 * Usage Example:
 * DmlProcessor processor = new DmlProcessor()
 *     .setRecords(accounts)
 *     .setOperation(DmlOperationExecutor.Operation.DO_INSERT)
 *     .withMaxRetry(3)
 *     .addBeforeInsertHook(new MyHook())
 *     .runNow();
 * 
 * @author DML Utility Team
 * @version 2.0
 */
public class DmlProcessor implements Queueable {
    
    // Core components
    private DmlOperationExecutor operationExecutor;
    private DmlHookManager hookManager;
    private DmlContext context;
    private DmlChunker chunker;
    
    // Configuration
    private List<SObject> records;
    private DmlOperationExecutor.Operation operation;
    private String externalIdField;
    private Boolean isAsync = false;
    private Boolean isLightweight = false;
    private Boolean enableLogging = false;
    private Boolean enableHeterogeneousMode = false;
    private Boolean enableRollback = false;
    private Integer maxRetry = 0;
    private Integer retryAttemptsLeft = 0;
    private Integer currentAttempt = 0;
    
    // Rollback management
    private Savepoint operationSavepoint;
    private Boolean rollbackCalled = false;
    
    // Results
    private List<SObject> failedRecords = new List<SObject>();
    private List<DmlResult> lastResults = new List<DmlResult>();
    
    // Validators and callbacks
    private List<Validator> validators = new List<Validator>();
    private List<ResultCallback> successCallbacks = new List<ResultCallback>();
    private List<ResultCallback> failureCallbacks = new List<ResultCallback>();
    private List<OnFailureHook> onFailureHooks = new List<OnFailureHook>();
    
    /**
     * Constructor initializes all components
     */
    public DmlProcessor() {
        this.chunker = new DmlChunker();
        this.hookManager = new DmlHookManager();
    }
    
    // Builder methods
    public DmlProcessor setRecords(List<SObject> records) { 
        this.records = records; 
        // Only validate homogeneous records if heterogeneous mode is not enabled
        if (!enableHeterogeneousMode) {
            this.chunker.validateHomogeneousRecords(records);
        }
        return this; 
    }
    
    public DmlProcessor setOperation(DmlOperationExecutor.Operation operation) { 
        this.operation = operation; 
        return this; 
    }
    
    public DmlProcessor runAsync() { 
        this.isAsync = true; 
        return this; 
    }
    
    public DmlProcessor setExternalId(String field) { 
        this.externalIdField = field; 
        return this; 
    }
    
    public DmlProcessor enableLightweightMode() { 
        this.isLightweight = true; 
        return this; 
    }
    
    public DmlProcessor withMaxRetry(Integer count) { 
        this.maxRetry = count; 
        this.retryAttemptsLeft = count; 
        return this; 
    }
    
    public DmlProcessor setAttempt(Integer attempt) {
        this.currentAttempt = attempt;
        return this;
    }
    
    public DmlProcessor withLogging() { 
        this.enableLogging = true; 
        return this; 
    }
    
    public DmlProcessor enableHeterogeneousMode() {
        this.enableHeterogeneousMode = true;
        return this;
    }
    
    public DmlProcessor enableRollback() {
        this.enableRollback = true;
        return this;
    }
    
    public DmlProcessor disableRetries() {
        this.maxRetry = 0;
        this.retryAttemptsLeft = 0;
        return this;
    }
    
    public DmlProcessor setChunkSize(Integer size) {
        this.chunker.setChunkSize(size);
        return this;
    }
    
    // Hook methods
    public DmlProcessor addBeforeInsertHook(DmlHookManager.Hook hook) {
        hookManager.addBeforeInsertHook(hook);
        return this;
    }
    
    public DmlProcessor addBeforeUpdateHook(DmlHookManager.Hook hook) {
        hookManager.addBeforeUpdateHook(hook);
        return this;
    }
    
    public DmlProcessor addBeforeDeleteHook(DmlHookManager.Hook hook) {
        hookManager.addBeforeDeleteHook(hook);
        return this;
    }
    
    public DmlProcessor addBeforeUpsertHook(DmlHookManager.Hook hook) {
        hookManager.addBeforeUpsertHook(hook);
        return this;
    }
    
    public DmlProcessor addAfterInsertHook(DmlHookManager.Hook hook) {
        hookManager.addAfterInsertHook(hook);
        return this;
    }
    
    public DmlProcessor addAfterUpdateHook(DmlHookManager.Hook hook) {
        hookManager.addAfterUpdateHook(hook);
        return this;
    }
    
    public DmlProcessor addAfterDeleteHook(DmlHookManager.Hook hook) {
        hookManager.addAfterDeleteHook(hook);
        return this;
    }
    
    public DmlProcessor addAfterUpsertHook(DmlHookManager.Hook hook) {
        hookManager.addAfterUpsertHook(hook);
        return this;
    }
    
    public DmlProcessor addHookErrorCallback(DmlHookManager.HookErrorCallback callback) {
        hookManager.addHookErrorCallback(callback);
        return this;
    }
    
    public DmlProcessor suppressHookExceptions() {
        hookManager.suppressHookExceptions();
        return this;
    }
    
    // Validation and callback methods
    public DmlProcessor addValidator(Validator validator) {
        validators.add(validator);
        return this;
    }
    
    public DmlProcessor addSuccessCallback(ResultCallback callback) {
        successCallbacks.add(callback);
        return this;
    }
    
    public DmlProcessor addFailureCallback(ResultCallback callback) {
        failureCallbacks.add(callback);
        return this;
    }
    
    public DmlProcessor addOnFailureHook(OnFailureHook hook) {
        onFailureHooks.add(hook);
        return this;
    }
    
    // Getters
    public List<SObject> getFailedRecords() {
        return failedRecords;
    }
    
    // Additional getters for retry handler integration
    public DmlOperationExecutor.Operation getOperation() {
        return operation;
    }
    
    public String getExternalIdField() {
        return externalIdField;
    }
    
    public Boolean getIsAsync() {
        return isAsync;
    }
    
    public Boolean getIsLightweight() {
        return isLightweight;
    }
    
    public Integer getMaxRetry() {
        return maxRetry;
    }
    
    public Boolean getEnableHeterogeneousMode() {
        return enableHeterogeneousMode;
    }
    
    public Boolean getEnableRollback() {
        return enableRollback;
    }
    
    public Boolean isSuccess() {
        return failedRecords.isEmpty();
    }
    
    public Boolean hasFailures() {
        return !failedRecords.isEmpty();
    }
    
    // Entry points
    public void runNow() {
        if (records == null || records.isEmpty()) {
            throw new IllegalArgumentException('You must call setRecords() before execution.');
        }
        
        if (isAsync) {
            System.enqueueJob(this);
            return;
        }
        
        doExecute();
    }
    
    public void execute(QueueableContext ctx) {
        this.currentAttempt = maxRetry - retryAttemptsLeft;
        doExecute();
    }
    
    public void executeDml() {
        if (isLightweight) {
            executeLightweight();
        } else {
            runNow();
        }
    }
    
    /**
     * Main execution method
     */
    @TestVisible
    private void doExecute() {
        validateBeforeRun();
        
        if (records == null || records.isEmpty()) {
            throw new IllegalArgumentException('You must call setRecords() before execution.');
        }
        
        // Clear previous results
        this.failedRecords.clear();
        this.lastResults.clear();
        
        // Set savepoint if rollback is enabled
        if (enableRollback) {
            validateSavepointLimits();
            this.operationSavepoint = Database.setSavepoint();
        }
        
        // Initialize components
        initializeComponents();
        
        // Execute based on mode
        if (enableHeterogeneousMode) {
            executeHeterogeneousWithPartialSuccess();
        } else {
            executeHomogeneous();
        }
        
        // Handle logging
        if (enableLogging) {
            handleLogging();
        }
    }
    
    /**
     * Validates savepoint governor limits
     */
    private void validateSavepointLimits() {
        Integer currentSavepoints = Limits.getSavepoints();
        if (currentSavepoints >= 8) { // Leave buffer of 2
            throw new DmlException('Cannot create savepoint. Too many savepoints in use (' + currentSavepoints + '/10). Cannot guarantee rollback capability.');
        }
    }
    
    /**
     * Executes homogeneous records (original logic)
     */
    private void executeHomogeneous() {
        // Process records in chunks
        for (List<SObject> chunk : chunker.split(records)) {
            try {
                processChunk(chunk);
            } catch (Exception ex) {
                handleChunkFailure(chunk, ex);
            }
        }
    }
    
    /**
     * Executes heterogeneous records with partial success allowed
     * Note: No automatic rollback - developer controls rollback via .rollback() API
     */
    private void executeHeterogeneousWithPartialSuccess() {
        // Group records by type
        Map<Schema.SObjectType, List<SObject>> groupedRecords = chunker.groupRecordsByType(records);
        
        // Get chunked records by type
        Map<Schema.SObjectType, List<List<SObject>>> chunkedByType = chunker.splitHeterogeneous(groupedRecords);
        
        // Process each type group - allow partial success
        for (Schema.SObjectType recordType : chunkedByType.keySet()) {
            List<List<SObject>> chunksOfType = chunkedByType.get(recordType);
            
            for (List<SObject> chunk : chunksOfType) {
                try {
                    processChunk(chunk); // Use normal processing with retries (if enabled)
                } catch (Exception ex) {
                    handleChunkFailure(chunk, ex);
                    // Continue processing other chunks - no automatic rollback
                }
            }
        }
    }
    
    /**
     * Manual rollback API - rolls back the entire operation
     */
    public void rollback() {
        if (!enableRollback) {
            throw new DmlException('Rollback is not enabled. Call enableRollback() before runNow() to use rollback functionality.');
        }
        
        if (operationSavepoint == null) {
            throw new DmlException('No savepoint available for rollback. Ensure runNow() was called successfully.');
        }
        
        if (rollbackCalled) {
            System.debug(LoggingLevel.WARN, 'Rollback already called for this operation');
            return;
        }
        
        try {
            Database.rollback(operationSavepoint);
            rollbackCalled = true;
            
            // Clear results since everything was rolled back
            this.failedRecords.clear();
            this.lastResults.clear();
            
            // Add all original records as failed due to rollback
            addFailedRecordsNoDuplicates(records);
            
            System.debug(LoggingLevel.INFO, 'Successfully rolled back DML operation affecting ' + records.size() + ' records');
            
        } catch (Exception ex) {
            throw new DmlException('Failed to rollback operation: ' + ex.getMessage(), ex);
        }
    }
    
    /**
     * Initializes all components with current configuration
     */
    private void initializeComponents() {
        this.operationExecutor = new DmlOperationExecutor(externalIdField);
        this.context = new DmlContext(convertOperation(operation), externalIdField, maxRetry, currentAttempt);
        this.context.setIsLightweight(isLightweight);
    }
    
    /**
     * Converts DmlOperationExecutor.Operation to DmlContext.Operation
     */
    private DmlContext.Operation convertOperation(DmlOperationExecutor.Operation operation) {
        if (operation == DmlOperationExecutor.Operation.DO_INSERT) return DmlContext.Operation.DO_INSERT;
        if (operation == DmlOperationExecutor.Operation.DO_UPDATE) return DmlContext.Operation.DO_UPDATE;
        if (operation == DmlOperationExecutor.Operation.DO_DELETE) return DmlContext.Operation.DO_DELETE;
        if (operation == DmlOperationExecutor.Operation.DO_UPSERT) return DmlContext.Operation.DO_UPSERT;
        return DmlContext.Operation.DO_INSERT; // Default
    }
    
    /**
     * Converts DmlOperationExecutor.Operation to DmlHookManager.Operation
     */
    private DmlHookManager.Operation convertToHookManagerOperation(DmlOperationExecutor.Operation operation) {
        if (operation == DmlOperationExecutor.Operation.DO_INSERT) return DmlHookManager.Operation.DO_INSERT;
        if (operation == DmlOperationExecutor.Operation.DO_UPDATE) return DmlHookManager.Operation.DO_UPDATE;
        if (operation == DmlOperationExecutor.Operation.DO_DELETE) return DmlHookManager.Operation.DO_DELETE;
        if (operation == DmlOperationExecutor.Operation.DO_UPSERT) return DmlHookManager.Operation.DO_UPSERT;
        return DmlHookManager.Operation.DO_INSERT; // Default
    }
    
    /**
     * Validates before execution
     */
    private void validateBeforeRun() {
        if (operation == null) {
            throw new IllegalArgumentException('You must call setOperation() before execution.');
        }
        
        // Only validate homogeneous records if heterogeneous mode is not enabled
        if (!enableHeterogeneousMode) {
            chunker.validateHomogeneousRecords(records);
        }
        
        if (operation == DmlOperationExecutor.Operation.DO_UPSERT && String.isBlank(externalIdField)) {
            throw new IllegalArgumentException('Missing External ID for upsert operation.');
        }
        
        if (isLightweight && operation == DmlOperationExecutor.Operation.DO_UPSERT) {
            throw new DmlException('Lightweight mode does not support upsert operations.');
        }
        
        if (isLightweight && enableHeterogeneousMode) {
            throw new DmlException('Lightweight mode does not support heterogeneous operations.');
        }
        
        if (enableRollback && isAsync) {
            throw new DmlException('Rollback is not supported for async operations. Async jobs run in separate transaction contexts.');
        }
        
        if (enableRollback && maxRetry > 0) {
            throw new DmlException('Choose either retries OR rollback, not both. Call disableRetries() when using rollback mode.');
        }
        
        if (enableRollback && isLightweight) {
            throw new DmlException('Lightweight mode does not support rollback operations.');
        }
    }
    
    /**
     * Processes a chunk of records
     */
    private void processChunk(List<SObject> chunk) {
        lastResults.clear();
        
        try {
            // Execute hooks
            hookManager.executeBeforeHooks(chunk, convertToHookManagerOperation(operation), context);
            
            // Validate
            validate(chunk);
            
            // Perform DML
            DmlOperationExecutor.DmlOperationResult result = operationExecutor.execute(chunk, operation);
            lastResults.addAll(convertResults(result));
            
            // Accumulate failed records (avoid duplicates)
            if (result.failedRecords != null && !result.failedRecords.isEmpty()) {
                addFailedRecordsNoDuplicates(result.failedRecords);
            }
            
            // Update context with error messages if any
            if (context != null && !result.errorMessages.isEmpty()) {
                context.setLogDetails(String.join(result.errorMessages, '\n'));
            }
            
            // Execute after hooks
            hookManager.executeAfterHooks(chunk, convertToHookManagerOperation(operation), context);
            
            // Route results
            routeResults(lastResults);
            
            // Handle retries
            handleRetries(result);
            
        } catch (Exception ex) {
            if (retryAttemptsLeft > 0) {
                scheduleRetry(chunk, ex);
            } else {
                handleChunkFailure(chunk, ex);
                // Add chunk to failed records if no retry (avoid duplicates)
                addFailedRecordsNoDuplicates(chunk);
            }
        }
    }
    
    /**
     * Handles logging when enabled
     */
    private void handleLogging() {
        if (context == null) {
            context = new DmlContext();
        }
        
        if (!context.getIsLightweight()) {
            context.setupLoggingContext(records, convertOperation(operation), failedRecords);
            Id logId = context.saveToLogObject();
            
            if (!failedRecords.isEmpty()) {
                context.addLogEntries(
                    logId,
                    failedRecords,
                    'DML failure during ' + String.valueOf(operation),
                    false
                );
            }
        }
    }
    
    /**
     * Executes lightweight mode
     */
    private void executeLightweight() {
        if (records == null || records.isEmpty()) {
            throw new IllegalArgumentException('You must call setRecords() before execution.');
        }
        initializeComponents();
        for (List<SObject> chunk : chunker.split(records)) {
            try {
                DmlOperationExecutor.DmlOperationResult result = operationExecutor.execute(chunk, operation);
                if (result.failedRecords != null && !result.failedRecords.isEmpty()) {
                    failedRecords.addAll(result.failedRecords);
                    if (context != null) context.incrementLightweightFailureCount();
                }
            } catch (Exception e) {
                handleLightweightChunkFailure(chunk, e);
            }
        }
    }
    
    /**
     * Handles lightweight chunk failures
     */
    private void handleLightweightChunkFailure(List<SObject> chunk, Exception e) {
        String errorMsg = String.format('[DmlProcessor] Lightweight DML chunk failed: {0}', new List<String>{ e.getMessage() });
        System.debug(LoggingLevel.WARN, errorMsg);
        
        if (context != null) {
            context.incrementLightweightFailureCount();
        }
        
        failedRecords.addAll(chunk);
    }
    
    /**
     * Validates records using validators
     */
    private void validate(List<SObject> chunk) {
        for (Validator validator : validators) {
            validator.validate(chunk);
        }
    }
    
    /**
     * Routes results to callbacks
     */
    private void routeResults(List<DmlResult> results) {
        for (DmlResult result : results) {
            if (result.success) {
                for (ResultCallback callback : successCallbacks) {
                    callback.handle(result.record, context, result.saveResult);
                }
            } else {
                for (ResultCallback callback : failureCallbacks) {
                    callback.handle(result.record, context, result.getFirstError());
                }
            }
        }
    }
    
    /**
     * Handles retries for failed operations
     */
    private void handleRetries(DmlOperationExecutor.DmlOperationResult result) {
        // Don't retry if rollback was called
        if (rollbackCalled) {
            return;
        }
        
        if (result.hasFailures && retryAttemptsLeft > 0 && isRetryWorthy(result)) {
            retryAttemptsLeft--;
            scheduleRetry(result.failedRecords, null);
        }
    }
    
    /**
     * Determines if a failed operation is worth retrying
     */
    private Boolean isRetryWorthy(DmlOperationExecutor.DmlOperationResult result) {
        // Custom validation exceptions are not retryable
        // Add other non-retryable error types here as needed
        return true;
    }
    
    /**
     * Schedules a retry for failed records
     */
    private void scheduleRetry(List<SObject> failedRecords, Exception ex) {
        if (failedRecords != null && !failedRecords.isEmpty()) {
            DmlRetryHandler.scheduleRetry(this, failedRecords, retryAttemptsLeft, currentAttempt + 1);
        }
    }
    
    /**
     * Handles chunk processing failures
     */
    private void handleChunkFailure(List<SObject> chunk, Exception ex) {
        for (ResultCallback callback : failureCallbacks) {
            for (SObject record : chunk) {
                callback.handle(record, context, ex);
            }
        }
        
        for (OnFailureHook hook : onFailureHooks) {
            hook.onFailure(chunk, context, ex);
        }
    }
    
    /**
     * Converts DmlOperationExecutor.DmlOperationResult to DmlResult list
     */
    private List<DmlResult> convertResults(DmlOperationExecutor.DmlOperationResult result) {
        List<DmlResult> results = new List<DmlResult>();
        
        if (result == null) {
            return results;
        }
        
        // Convert failed records to DmlResult objects
        if (result.failedRecords != null && !result.failedRecords.isEmpty()) {
            for (SObject failedRecord : result.failedRecords) {
                DmlResult dmlResult = new DmlResult();
                dmlResult.record = failedRecord;
                dmlResult.success = false;
                dmlResult.errors = new List<Database.Error>();
                results.add(dmlResult);
            }
        }
        
        return results;
    }
    
    /**
     * Adds failed records to the failed records list, avoiding duplicates
     * @param recordsToAdd Records to add to failed records list
     */
    private void addFailedRecordsNoDuplicates(List<SObject> recordsToAdd) {
        Set<Id> existingFailedIds = new Set<Id>();
        for (SObject existingRecord : this.failedRecords) {
            if (existingRecord.Id != null) {
                existingFailedIds.add(existingRecord.Id);
            }
        }
        
        for (SObject record : recordsToAdd) {
            // For records with IDs, check for duplicates. For new records (no ID), always add
            if (record.Id == null || !existingFailedIds.contains(record.Id)) {
                this.failedRecords.add(record);
                if (record.Id != null) {
                    existingFailedIds.add(record.Id);
                }
            }
        }
    }
    
    /**
     * Clones the processor with new records and retry settings
     */
    public DmlProcessor cloneWith(List<SObject> newRecords, Integer retryLeft, Integer attempt) {
        List<SObject> clonedRecords = new List<SObject>();
        for (SObject rec : newRecords) {
            clonedRecords.add(rec.clone(false, true, true, true));
        }
        
        DmlProcessor cloned = new DmlProcessor()
            .setOperation(operation)
            .setExternalId(externalIdField)
            .withMaxRetry(maxRetry)
            .setAttempt(attempt);
        
        // Enable modes before setting records to avoid validation issues
        if (this.enableHeterogeneousMode) {
            cloned.enableHeterogeneousMode();
        }
        
        if (this.enableRollback) {
            cloned.enableRollback();
        }
        
        cloned.setRecords(clonedRecords);
        cloned.retryAttemptsLeft = retryLeft;
        
        if (this.isAsync) {
            cloned.runAsync();
        }
        
        if (this.isLightweight) {
            cloned.enableLightweightMode();
        }
        
        return cloned;
    }
    
    // Interfaces
    public interface Validator { 
        void validate(List<SObject> records); 
    }
    
    public interface ResultCallback {
        void handle(SObject record, DmlContext context, Object resultOrError);
    }
    
    public interface OnFailureHook {
        void onFailure(List<SObject> failed, DmlContext context, Exception ex);
    }
    
    public class DmlResult {
        public SObject record;
        public Boolean success;
        public List<Database.Error> errors = new List<Database.Error>();
        public Database.SaveResult saveResult;
        public Database.DeleteResult deleteResult;
        public Database.UpsertResult upsertResult;

        public DmlResult() {}

        public DmlResult(SObject record, Database.SaveResult res) {
            this.record = record; 
            this.success = true; 
            this.saveResult = res;
        }
        
        public DmlResult(SObject record, Database.DeleteResult res) {
            this.record = record; 
            this.success = true; 
            this.deleteResult = res;
        }
        
        public DmlResult(SObject record, Database.UpsertResult res) {
            this.record = record; 
            this.success = true; 
            this.upsertResult = res;
        }
        
        public DmlResult(SObject record, List<Database.Error> errors) {
            this.record = record; 
            this.success = false; 
            this.errors = errors;
        }
        
        public Exception getFirstError() {
            return (!errors.isEmpty()) ? new DmlException(errors[0].getMessage()) : new DmlException('Unknown failure');
        }
    }
    
    public class DmlException extends Exception {}
}