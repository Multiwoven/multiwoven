import { useState, useEffect, useCallback, useRef } from 'react';
import { Flex, Text, IconButton, Box, Icon, Image } from '@chakra-ui/react';
import { Edge } from '@xyflow/react';
import { FiClock, FiX, FiEdit } from 'react-icons/fi';
import ChatbotInterface from '@/enterprise/components/ChatbotInterface/ChatbotInterface';
import P2WEventTimeline from '@/enterprise/components/ChatbotInterface/P2WEventTimeline';
import P2WStatusBar from '@/enterprise/components/ChatbotInterface/P2WStatusBar';
import EmptyWorkflowChat from '@/assets/images/empty-workflow-ai-chat.svg';
import { useParams } from 'react-router-dom';
import { useAssistantConfigStore } from '@/enterprise/store/useAssistantConfigStore';
import useAgentStore from '@/enterprise/store/useAgentStore';
import { FlowComponent } from '@/enterprise/views/Agents/types';
import { useWorkflowBuilderSession } from '@/enterprise/hooks/useWorkflowBuilderSession';
import { useP2WEventTimeline } from '@/enterprise/hooks/useP2WEventTimeline';
import { deliverP2WClarification, getWorkflowById } from '@/enterprise/services/agents';
import { createMessage } from '@/enterprise/components/ChatbotInterface/handlers';
import { WorkflowResponseData } from '@/enterprise/components/ChatbotInterface/types';
import { useP2WStream } from '@/enterprise/hooks/useP2WStream';
import type { P2WEvent } from '@/enterprise/services/types';
import type { ClarificationAnswer } from '@/enterprise/components/ChatbotInterface/p2wTypes';
import WorkflowSessionsDrawer from './WorkflowSessionsDrawer';
import { transformComponents, transformEdges } from '../utils';
import { runFormValidation } from '@/enterprise/hooks/utils/validationUtils';
import { resolveCollisions } from '@/enterprise/hooks/utils/resolveCollisions';

const SUGGESTED_QUESTIONS = [
  'Help me build a chat assistant using my knowledge base.',
  'Set up a chat workflow with PII guardrails and a custom prompt.',
  'Build a workflow that routes user questions to different models based on cost.',
  'Create an AI agent that uses tools and knowledge base.',
];

interface AIWorkflowBuilderProps {
  isOpen: boolean;
  onClose: () => void;
}

const AIBuilderHeader = ({
  onNewChat,
  onClose,
  onOpenHistory,
}: {
  onNewChat: () => void;
  onClose: () => void;
  onOpenHistory: () => void;
}) => (
  <Flex
    align='center'
    px='20px'
    py='16px'
    borderBottomWidth='1px'
    borderColor='gray.400'
    flexShrink={0}
    width='100%'
  >
    <Text flex={1} fontSize='sm' fontWeight={600} color='black.500'>
      AI Workflow Builder
    </Text>
    <Flex gap='12px'>
      <IconButton
        aria-label='New Chat'
        icon={<Icon as={FiEdit} boxSize='14px' />}
        variant='outline'
        width='fit-content'
        size='sm'
        onClick={onNewChat}
      />
      <IconButton
        aria-label='History'
        icon={<Icon as={FiClock} boxSize='14px' />}
        variant='outline'
        width='fit-content'
        size='sm'
        onClick={onOpenHistory}
      />
      <IconButton
        data-testid='ai-builder-close-btn'
        aria-label='Close'
        icon={<Icon as={FiX} boxSize='14px' />}
        variant='outline'
        width='fit-content'
        size='sm'
        onClick={onClose}
      />
    </Flex>
  </Flex>
);

const AIBuilderEmptyState = () => (
  <Flex direction='column' align='center' justify='center' flex={1} gap='12px'>
    <Box borderRadius='12px' p='12px' display='flex' alignItems='center' justifyContent='center'>
      <Image src={EmptyWorkflowChat} alt='empty workflow chat' />
    </Box>
    <Flex flexDir={'column'} gap={'8px'} mt={'-44px'}>
      <Text fontWeight={600} color='black.500' textAlign='center'>
        What do you want to build?
      </Text>
      <Text fontSize='sm' color='gray.600' textAlign='center'>
        Describe what you want to build and I&apos;ll assist you by creating a new workflow or
        modifying existing ones.
      </Text>
    </Flex>
  </Flex>
);

const AIWorkflowBuilder = ({ isOpen, onClose }: AIWorkflowBuilderProps) => {
  const id = useParams().id ?? '';
  const {
    setWorkflow,
    setNodes,
    setEdges,
    currentWorkflow,
    setSelectedComponent,
    setComponentFormErrors,
  } = useAgentStore();
  const { setMessages, activeSession, configs } = useAssistantConfigStore();
  const { start: startP2WStream, stop, isRunning } = useP2WStream(id);
  const { items, onEvent: onTimelineEvent, reset, rejectClarification } = useP2WEventTimeline(id);
  const sessionIdRef = useRef<string | null>(null);
  const [terminalEvent, setTerminalEvent] = useState<'error' | 'max_turns' | null>(null);
  const [selectedContextComponents, setSelectedContextComponents] = useState<FlowComponent[]>([]);
  const [pendingEdges, setPendingEdges] = useState<Edge[]>([]);
  const [isHistoryOpen, setIsHistoryOpen] = useState(false);
  const [isClarificationLoading, setIsClarificationLoading] = useState(false);

  const { handleNewChat, handleSessionExpired, workflowSessions, setActiveSession } =
    useWorkflowBuilderSession({
      workflowId: id,
      onNewChat: () => {
        setSelectedContextComponents([]);
        reset();
        setTerminalEvent(null);
      },
    });

  useEffect(() => {
    if (pendingEdges.length > 0) {
      const timer = setTimeout(() => {
        setEdges(() => pendingEdges);
        setPendingEdges([]);
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [pendingEdges, setEdges]);

  const contextComponents = currentWorkflow?.workflow.components ?? [];

  const handleToggleContextComponent = (component: FlowComponent) => {
    setSelectedContextComponents((prev) =>
      prev.some((c) => c.id === component.id)
        ? prev.filter((c) => c.id !== component.id)
        : [...prev, component],
    );
  };

  const handleStop = useCallback(() => {
    stop();
    reset();
    setTerminalEvent(null);
    setIsClarificationLoading(false);
    sessionIdRef.current = null;
  }, [stop, reset]);

  const handleSend = async (prompt: string): Promise<void> => {
    if (!prompt.trim()) return;
    setSelectedComponent(null);
    reset();
    setTerminalEvent(null);

    const sessionId = await startP2WStream(prompt, selectedContextComponents, {
      onEvent: (event: P2WEvent) => {
        onTimelineEvent(event);

        if (event.type === 'p2w.error') setTerminalEvent('error');
        if (event.type === 'p2w.max_turns') setTerminalEvent('max_turns');
      },
      onComplete: async () => {
        try {
          const response = await getWorkflowById(id);
          if (response?.data?.attributes) {
            const attributes = response.data.attributes;
            setWorkflow({ workflow: { ...attributes } });
            const rawNodes = transformComponents(attributes.components ?? []);
            const freshNodes = resolveCollisions(rawNodes);
            setNodes(() => freshNodes);
            setTimeout(() => {
              setComponentFormErrors(runFormValidation(freshNodes));
            }, 0);
            setPendingEdges(transformEdges(attributes.edges ?? []));
            const workflowMessage = createMessage('workflow', '', false);
            workflowMessage.workflow_data = response as WorkflowResponseData;
            setMessages(activeSession, (prev) => [...prev, workflowMessage], configs.dataAppId);
          }
        } catch {
          const msg = createMessage(
            'error',
            'Workflow was generated but could not be loaded.',
            false,
          );
          setMessages(activeSession, (prev) => [...prev, msg], configs.dataAppId);
        }
        setSelectedContextComponents([]);
      },
      onError: (error: string) => {
        if (/\b(401|403)\b/.test(error)) {
          handleSessionExpired();
          return;
        }
        const msg = createMessage('error', error, false);
        setMessages(activeSession, (prev) => [...prev, msg], configs.dataAppId);
      },
    }).catch((err: unknown) => {
      handleStop();
      const text = err instanceof Error ? err.message : 'Failed to start workflow generation.';
      if (/\b(401|403)\b/.test(text)) {
        handleSessionExpired();
        return null;
      }
      const msg = createMessage('error', text, false);
      setMessages(activeSession, (prev) => [...prev, msg], configs.dataAppId);
      return null;
    });

    if (sessionId) sessionIdRef.current = sessionId;
  };

  const handleClarificationSubmit = useCallback(
    async (clarificationId: string, answer: ClarificationAnswer) => {
      const sessionId = sessionIdRef.current;
      const isEmpty =
        answer === null ||
        answer === undefined ||
        (typeof answer === 'string' && !answer.trim()) ||
        (Array.isArray(answer) && answer.length === 0);
      if (!sessionId || isEmpty) return;
      setIsClarificationLoading(true);
      const trimmedAnswer = typeof answer === 'string' ? answer.trim() : answer;
      try {
        await deliverP2WClarification(sessionId, clarificationId, trimmedAnswer);
      } catch (err) {
        const text =
          err instanceof Error ? err.message : 'Failed to deliver your answer. Please try again.';
        const msg = createMessage('error', text, false);
        setMessages(activeSession, (prev) => [...prev, msg], configs.dataAppId);
      } finally {
        setIsClarificationLoading(false);
      }
    },
    [activeSession, configs.dataAppId, setMessages],
  );

  const handleClarificationReject = useCallback(
    (clarificationId: string) => {
      rejectClarification(clarificationId);
      handleStop();
    },
    [rejectClarification, handleStop],
  );

  return (
    <Box
      position='absolute'
      top='0'
      left='0'
      height='100%'
      width='480px'
      zIndex={10}
      transform={isOpen ? 'translateX(0)' : 'translateX(-100%)'}
      transition='transform 0.3s ease'
      bg='white'
      borderRightWidth='1px'
      borderColor='gray.400'
      boxShadow='lg'
      display='flex'
      flexDirection='column'
      overflow='hidden'
    >
      {isHistoryOpen ? (
        <WorkflowSessionsDrawer
          chatHistory={workflowSessions}
          activeSession={activeSession}
          setActiveSession={setActiveSession}
          onNewChat={handleNewChat}
          onClose={onClose}
          onBack={() => setIsHistoryOpen(false)}
          onSend={handleSend}
          contextComponents={contextComponents}
          selectedContextComponents={selectedContextComponents}
          onToggleContextComponent={handleToggleContextComponent}
        />
      ) : (
        <ChatbotInterface
          isWorkflowBuilder
          colors={{ userMessageBg: 'gray.400', userTextColor: 'black.500' }}
          header={
            <AIBuilderHeader
              onClose={onClose}
              onNewChat={handleNewChat}
              onOpenHistory={() => setIsHistoryOpen(true)}
            />
          }
          emptyState={<AIBuilderEmptyState />}
          suggestedQuestions={SUGGESTED_QUESTIONS}
          onSend={handleSend}
          padding='20px'
          contextComponents={contextComponents}
          selectedContextComponents={selectedContextComponents}
          onToggleContextComponent={handleToggleContextComponent}
          streamingPlaceholder={
            items.length > 0 ? (
              <P2WEventTimeline
                items={items}
                terminalEvent={terminalEvent}
                isClarificationLoading={isClarificationLoading}
                onClarificationAnswer={handleClarificationSubmit}
                onClarificationReject={handleClarificationReject}
              />
            ) : undefined
          }
          wrapFooter={(defaultInput) => (
            <P2WStatusBar isRunning={isRunning} onStop={handleStop}>
              {defaultInput}
            </P2WStatusBar>
          )}
        />
      )}
    </Box>
  );
};

export default AIWorkflowBuilder;
