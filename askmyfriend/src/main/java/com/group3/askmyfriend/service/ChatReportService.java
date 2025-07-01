package com.group3.askmyfriend.service;

import com.group3.askmyfriend.dto.ChatReportRequestDto;
import com.group3.askmyfriend.entity.ChatReport;
import com.group3.askmyfriend.entity.UserEntity;
import com.group3.askmyfriend.repository.ChatReportRepository;
import com.group3.askmyfriend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ChatReportService {

    @Autowired
    private ChatReportRepository chatReportRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public void reportMessage(ChatReportRequestDto dto, Long reporterId) {
        UserEntity reporter = userRepository.findById(reporterId)
                .orElseThrow(() -> new IllegalArgumentException("신고자를 찾을 수 없습니다."));

        ChatReport report = new ChatReport();
        report.setMessageId(dto.getMessageId());
        report.setReason(dto.getReason());
        report.setReporter(reporter);
        report.setStatus(ChatReport.ReportStatus.PENDING); // 기본값 설정

        chatReportRepository.save(report);
    }

    @Transactional(readOnly = true)
    public List<ChatReport> getAllChatReports() {
        return chatReportRepository.findAll();
    }

    // 상태 업데이트 메서드 추가
    @Transactional
    public void updateStatus(Long reportId, String status) {
        ChatReport report = chatReportRepository.findById(reportId)
                .orElseThrow(() -> new IllegalArgumentException("신고를 찾을 수 없습니다."));
        
        ChatReport.ReportStatus newStatus = ChatReport.ReportStatus.valueOf(status.toUpperCase());
        report.setStatus(newStatus);
        
        chatReportRepository.save(report);
    }
}
