/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers/sfdc-convert-documents-to-files
 * License: BSD 3-Clause License
 */
public class Tag2Topic_ConversionService {

    public void convertTagsToTopics( List<ContentVersion> files ) {

        System.debug( 'Tag2Topic_ConversionService.convertTagsToTopics' );

        Map<ID, Set<String>> documentIdToTopicNamesMap = getDocumentIdToTopicNamesMap( files );
        Map<String, Topic> tagNameToTopicMap = getOrCreateTopicByTagNameMap( files );

        // todo assign topics to files

    }

    // --------------------------------------------

    private Map<ID, Set<String>> getDocumentIdToTopicNamesMap( List<ContentVersion> files ) {

        Set<ID> documentIds = getContentDocumentIds( files );

        // topics that are already assigned to documents
        // if tag name matches a topic name in this map, then don't redundantly assign topic to file
        Map<ID, Set<String>> documentIdToTopicNamesMap = new Map<ID, Set<String>>();

        for ( List<TopicAssignment> assignments : [
                SELECT TopicId, Topic.Name, EntityId
                FROM TopicAssignment
                WHERE EntityId IN :documentIds
        ] ) {
            for ( TopicAssignment assignment : assignments ) {
                Set<String> topicNames = documentIdToTopicNamesMap.get( assignment.EntityId );
                if ( topicNames == null ) {
                    topicNames = new Set<String>();
                    documentIdToTopicNamesMap.put( assignment.EntityId, topicNames );
                }
                topicNames.add( assignment.Topic.Name.toLowerCase() );
            }
        }

        return documentIdToTopicNamesMap;
    }

    /**
     * Returns a map whose keys are tag names assigned to the given files,
     * and the map values are the Topic records with the same tag names.
     *
     * If a Topic does not exist with same name as a tag,
     * then this method creates new Topics.
     *
     * The returned map will have an entry for each tag among the files.
     */
    private Map<String, Topic> getOrCreateTopicByTagNameMap( List<ContentVersion> files ) {

        Map<String, Topic> topicByTagNameMap = getTopicByTagNameMap( files );

        // identify tags that are not yet topics
        for ( ContentVersion file : files ) {
            if ( String.isNotBlank( file.TagCsv ) ) {
                for ( String tagName : file.TagCsv.split( ',' ) ) {
                    if ( !topicByTagNameMap.containsKey( tagName.toLowerCase() ) ) {
                        System.debug( 'new topic: ' + tagName );
                        topicByTagNameMap.put( tagName.toLowerCase(), new Topic( Name = tagName ) );
                    } else {
                        System.debug( 'topic already exists: ' + tagName );
                    }
                }
            }
        }

        upsert topicByTagNameMap.values();

        return topicByTagNameMap;
    }

    private Map<String, Topic> getTopicByTagNameMap( List<ContentVersion> files ) {

        Set<String> tagNames = getFileTagNames( files );

        // topics that already exist that match tag names
        // these are candidates for topic assignment
        // if a tag name exists in this map, then don't redundantly create topic
        Map<String, Topic> topicsByTagNameMap = new Map<String, Topic>();

        for ( List<Topic> topics : [
                SELECT Id, Name
                FROM Topic
                WHERE Name IN :tagNames
        ] ) {
            for ( Topic t : topics ) {
                topicsByTagNameMap.put( t.Name.toLowerCase(), t );
            }
        }

        return topicsByTagNameMap;
    }

    private Set<ID> getContentDocumentIds( List<ContentVersion> files ) {

        Set<ID> documentIds = new Set<ID>();

        for ( ContentVersion file : files ) {
            documentIds.add( file.ContentDocumentId );
        }

        return documentIds;
    }

    private Set<String> getFileTagNames( List<ContentVersion> files ) {

        Set<String> tagNames = new Set<String>();

        for ( ContentVersion file : files ) {
            if ( String.isNotBlank( file.TagCsv ) ) {
                tagNames.addAll( file.TagCsv.split( ',' ) );
            }
        }

        return tagNames;
    }

}
/*
BSD 3-Clause License

Copyright (c) 2018, Doug Ayers, douglascayers.com
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/