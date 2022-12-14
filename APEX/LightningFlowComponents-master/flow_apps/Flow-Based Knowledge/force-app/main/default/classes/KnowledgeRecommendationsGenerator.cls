public with sharing class KnowledgeRecommendationsGenerator 
{
    static final String DUMMY_FLOW_API_NAME = 'Flow_Based_Strategy';

    @InvocableMethod
    public static List<Responses> generateKnowledgeRecommendations(List<Requests> requests) {
        List<Responses> responsesList = new List<Responses>();
        List<Recommendation> recommendations = new List<Recommendation>();

        for(Requests rqst : requests) {
            Responses rspns = new Responses();
            String searchString = rqst.searchString;
            String languageLocale = rqst.languageLocale;
            // String articleType = rqst.articleType;
            String topic = rqst.topic;
            String publicationStatus = rqst.publicationStatus;
            Integer resultLimit = rqst.resultLimit;
            
            if(resultLimit == null) {
                resultLimit = 5;
            }

            String queryString = 'FIND {' + searchString + '} IN ALL FIELDS RETURNING KnowledgeArticleVersion(';
            queryString += 'id, title WHERE Language = :languageLocale';
            /* Commented, because such field doesn't exists on KnowledgeArticleVersion object
            if(articleType != null)
            {
                queryString += ' AND ArticleType = :articleType';
            }
            */
            if(topic != null) {
                queryString += ' AND Title = :topic';
            }

            if(!String.isEmpty(publicationStatus)) {
                queryString += ' AND PublishStatus = :publicationStatus';
            }

            queryString += ') WITH SNIPPET (target_length=120) LIMIT ' + resultLimit;
            Search.SearchResults searchResults = Search.find(queryString);
            List<Search.SearchResult> articleList = searchResults.get('KnowledgeArticleVersion');
            
            for(Search.SearchResult searchResult : articleList) {
                Recommendation recommendation = new Recommendation();
                KnowledgeArticleVersion article = (KnowledgeArticleVersion) searchResult.getSObject();
                
                recommendation.ExternalId = article.Id;
                recommendation.Name = article.Title;
                recommendation.Description = searchResult.getSnippet();
                recommendation.ActionReference = 'Run_Knowledge_Flow_Basically';

                recommendations.add(recommendation);
            }
            rspns.outputRecommendations = recommendations;
            responsesList.add(rspns);
        }
        return responsesList;
    }

    @AuraEnabled
    public static List<Recommendation> executeNBAFlow(String strategyName, String contextRecordId, String searchString) {
        Flow.Interview curInterview = Flow.Interview.createInterview(strategyName, new Map<String,Object>{'recordId' =>contextRecordId, 'searchString' => searchString });
        curInterview.start();
        System.debug('searchString' + searchString);
        System.debug(curInterview.getVariableValue('outputRecommendations'));
        return (List<Recommendation>)curInterview.getVariableValue('outputRecommendations');
    }

    @AuraEnabled
    public static string launchFLow(Recommendation rec, String strategyName, String contextRecordId){
        List<FlowDefinitionView> flowDefList = [SELECT Id, ProcessType, TriggerType, ApiName FROM FlowDefinitionView WHERE apiName = :rec.ActionReference];
        if(flowDefList.size() > 0) {
            if( flowDefList[0].ProcessType == 'AutoLaunchedFlow') {
                Flow.Interview curInterview = Flow.Interview.createInterview(rec.ActionReference, new Map<String, Object>{
                    'recordId' => rec.ExternalId,
                    'strategyName' => strategyName,
                    'userId' => UserInfo.getUserId(),
                    'recommendationName' => rec.Name
                });
                curInterview.start();
            }
         //a limitation in the recordation interface means that a strategyName is still required 
         //to record a reaction even if the recommendation was generated by a flow and not a legacy-style strategy. 
         //Use any string that matches an existing strategy (the strategy won't be run and doesn't have to do anything)
         
        ConnectApi.RecommendationReactionInput reactionInput = new ConnectApi.RecommendationReactionInput();
        reactionInput.strategyName = DUMMY_FLOW_API_NAME;
        reactionInput.targetActionName = rec.ActionReference;
        reactionInput.targetId =  contextRecordId;
        reactionInput.ExternalId = (rec.Name.length() < 18) ? rec.Name :rec.Name.substring(0,18);
        reactionInput.reactionType = ConnectApi.RecommendationReactionType.Accepted;
        if(!Test.isRunningTest()) {
            ConnectApi.RecommendationReaction reactionResult = ConnectApi.NextBestAction.setRecommendationReaction(reactionInput);
        }

        return flowDefList[0].ProcessType;
        } else {
            throw new AuraHandledException ('Incorrect flow name : ' + rec.ActionReference);
        }
    }

    public class InvocableErrorException extends Exception {}

    public class Requests {
        @InvocableVariable(required=true)
        public String searchString;

        @InvocableVariable(required=true)
        public String languageLocale;

        @InvocableVariable
        public Integer resultLimit;

        // @InvocableVariable
        // public String articleType;
        
        @InvocableVariable
        public String topic;
        
        @InvocableVariable
        public String publicationStatus;
    }

    public class Responses {
        @InvocableVariable
        public List<Recommendation> outputRecommendations;
    }
    
}