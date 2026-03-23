package com.skep.notification.dto;

import lombok.*;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageReadStatusResponse {

    private UUID messageId;
    private Long totalRecipients;
    private Long totalReads;
    private Long totalConfirmed;
    private List<ReadStatusDetail> readDetails;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class ReadStatusDetail {
        private UUID userId;
        private Boolean hasRead;
        private Boolean hasConfirmed;
    }

}
