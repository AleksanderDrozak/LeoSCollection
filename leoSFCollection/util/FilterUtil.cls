@SuppressWarnings('PMD.AvoidGlobalModifier')
global abstract class FilterUtil {
    
    global class FilterEvaluatorException extends Exception {}

    global class FilterExpressionTransformer {

        private Map<FilterJoinOperators, Type> operatorsMap;

        global FilterExpressionTransformer(Map<FilterJoinOperators, Type> operatorsMap) {
            this.operatorsMap = operatorsMap;
        }

        private BooleanFunction getDoubleExpressionFunction(BooleanFunction functionA, BooleanFunction functionB, FilterJoinOperators operator) {
            BooleanFunctionAgregatorDouble handler = (BooleanFunctionAgregatorDouble) operatorsMap.get(operator).newInstance();
            return (BooleanFunction) handler.initialize(functionA, functionB);
        }

        private BooleanFunction getSingleExpressionFunction(BooleanFunction functionA, FilterJoinOperators operator) {
            BooleanFunctionAgregatorSingle handler = (BooleanFunctionAgregatorSingle) operatorsMap.get(operator).newInstance();
            return (BooleanFunction) handler.initialize(functionA);
        }
    
        private String normalizeExpression(String expression) {
            return expression;
        }

        global BooleanFunction evaluate(String expression, List<BooleanFunction> functionsToEvaluate) {
            BooleanFunctionTree expressionTree = new BooleanFunctionTree(this.normalizeExpression(expression));
            return evaluate(expressionTree, functionsToEvaluate);
        }

        private BooleanFunction evaluate(BooleanFunctionTree expressionTree, List<BooleanFunction> functionsToEvaluate) {
            
            if(expressionTree.value != null) {
                return functionsToEvaluate[expressionTree.value - 1];
            }

            switch on expressionTree.operator {
                when AND_OPERATOR {
                    return this.evaluateDoubleExpression(expressionTree, functionsToEvaluate, FilterJoinOperators.AND_OPERATOR);
                }
                when OR_OPERATOR {
                    return this.evaluateDoubleExpression(expressionTree, functionsToEvaluate, FilterJoinOperators.OR_OPERATOR);
                }
                // TODO Implement not opeartor
                // when NOT_OPERATOR {
                //     return this.evaluateSingleExpression(expressionTree, functionsToEvaluate, FilterJoinOperators.NOT_OPERATOR);
                // }
                when else {
                    throw new FilterEvaluatorException('Unhandled operator' + expressionTree.operator);
                }
            }
        }

        private BooleanFunction evaluateDoubleExpression(BooleanFunctionTree expressionTree, List<BooleanFunction> functionsToEvaluate, FilterJoinOperators operator) {
            BooleanFunction functionA = this.evaluate(expressionTree.nodeA, functionsToEvaluate);
            BooleanFunction functionB = this.evaluate(expressionTree.nodeB, functionsToEvaluate);
            return this.getDoubleExpressionFunction(functionA, functionB, operator);
        }
    }

    global class BooleanFunctionTree {
        FilterJoinOperators operator;
        Integer value;
        BooleanFunctionTree nodeA;
        BooleanFunctionTree nodeB;
        Integer nestingLevel;
        private final Pattern isGroupInBrackets = Pattern.compile('\\(.*?\\)');
        private final Pattern isNumberInBracketsPattern = Pattern.compile('\\(\\d+\\)');

        public BooleanFunctionTree(String expression, Integer nestingLevel) {

            if(nestingLevel > 20){
                throw new FilterEvaluatorException('Max number of 20 expression nesting exceeded on expression ' + expression);
            }

            this.nestingLevel = nestingLevel;

            try{
                this.handleExpression(expression);
            }
            catch(Exception error){
                throw new FilterEvaluatorException(error.getMessage() + ' happend on ' + expression + ' Stack trace ' + error.getStackTraceString());
            }
        }

        public BooleanFunctionTree(String expression) { 
            this(expression, 1);
        }

        private String removeBracketsAround(String expression) {
            return expression.removeStart('(').removeEnd(')');
        }

        /** example : (1 AND 2 AND 3 AND 4) returns ['1 ', 'AND 2 AND 3 AND 4'] */
        private List<String> getFirstNumberAndRestTuplet(String expression) {
            return this.removeBracketsAround(expression).replaceFirst('(\\d+)','$1NUM').split('NUM', 2);
        }
        
        private Integer countMatches(Matcher currentMatch) {
            Integer numberOfMatches = 0;

            while (currentMatch.find()) {
                numberOfMatches++;
            }

            /** after calculation need to reset matcher to first find, to group(0) be populated */
            this.restoreMatcherToGroupZeroBeAvailable(currentMatch);

            return numberOfMatches;
        }

        private void restoreMatcherToGroupZeroBeAvailable(Matcher currentMatch) {
            currentMatch.reset();
            currentMatch.find();
        }

        private void handleExpression(String expression) {
            // TODO Implement NOT opeartor
            expression = expression.trim().toUpperCase();

            if(this.isNotNestedExpression(expression) || this.isNumberInBracketsPattern.matcher(expression).find()) {
                this.value = Integer.valueOf(expression);
                return;
            }

            final Pattern isGroupInBrackets = Pattern.compile('\\(.*?\\)');
            final Pattern isNumberInBracketsPattern = Pattern.compile('\\(\\d+\\)');

            Matcher currentMatch = isGroupInBrackets.matcher(expression);
            Integer numberOfGroups = this.countMatches(currentMatch);

            if(numberOfGroups == 0) {
                throw new FilterEvaluatorException('Invalid expression ' + expression);
            }           

            if(numberOfGroups == 1) {
                List<String> expressions = this.getFirstNumberAndRestTuplet(expression);
                String aNodeExpression = expressions[0].trim();
                String restExpression = expressions[1].trim();
                this.nodeA = new BooleanFunctionTree(aNodeExpression, this.nestingLevel + 1);
                this.operator = this.getOperator(restExpression);
                String bNodeExpression = restExpression.replaceFirst('(AND|OR|NOT)','');
                this.nodeB = bNodeExpression.length() > 0 ? new BooleanFunctionTree(bNodeExpression, this.nestingLevel + 1) : null;
                return;
            }

            String aNodeExpression = currentMatch.group(0);
            String restExpression = aNodeExpression.difference(expression).trim();
            this.nodeA = new BooleanFunctionTree(aNodeExpression, this.nestingLevel + 1);
            this.operator = this.getOperator(restExpression);
            String bNodeExpression = restExpression.replaceFirst('(AND|OR|NOT)','');
            this.nodeB = new BooleanFunctionTree(bNodeExpression, this.nestingLevel + 1);
        }

        private FilterJoinOperators getOperator(String subExpresion) {
            
            String subExpresionClean = subExpresion.trim();
            
            if(subExpresionClean.startsWith('AND')){
                return FilterJoinOperators.AND_OPERATOR;
            }

            if(subExpresionClean.startsWith('OR')){
                return FilterJoinOperators.OR_OPERATOR;
            }

            if(subExpresionClean.startsWith('NOT')){
                return FilterJoinOperators.NOT_OPERATOR;
            }

            return null;
        }

        private Boolean isNotNestedExpression(String expression) {
            return !expression.contains('(') && this.isNotLogicalExpression(expression);
        }

        private Boolean isNotLogicalExpression(String expression) {
            return !expression.contains('AND') && !expression.contains('OR') && !expression.contains('NOT');
        }
    }

    global enum FilterJoinOperators {
        AND_OPERATOR,
        OR_OPERATOR,
        NOT_OPERATOR
    }

    global interface BooleanFunctionAgregatorSingle {
        BooleanFunction initialize(BooleanFunction handler);
    }

    global interface BooleanFunctionAgregatorDouble {
        BooleanFunction initialize(BooleanFunction handlerA, BooleanFunction handlerB);
    }

}
