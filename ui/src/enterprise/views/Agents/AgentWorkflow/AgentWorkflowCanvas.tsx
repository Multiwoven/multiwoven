import { Box, Button, Flex, Image, HStack } from '@chakra-ui/react';
import {
  ReactFlow,
  useReactFlow,
  applyNodeChanges,
  applyEdgeChanges,
  ReactFlowProvider,
  addEdge,
  Background,
  BackgroundVariant,
  Edge,
  NodeTypes,
} from '@xyflow/react';
import { useEffect, useCallback, useRef, useState } from 'react';
import '@xyflow/react/dist/style.css';
import Sidebar from './Sidebar/Sidebar';
import Configbar from './Configbar/Configbar';
import useAgentStore from '@/enterprise/store/useAgentStore';
import { FlowComponent } from '../types';
import { getEdgeDataFromId } from '@/enterprise/utils/edgeJsonParser';
import { useParams } from 'react-router-dom';
import ShortUniqueId from 'short-unique-id';
import { constructEdgeId } from './utils';
import FiUndo from '@/assets/icons/FiUndo.svg';
import FiRedo from '@/assets/icons/FiRedo.svg';
import FiZoomIn from '@/assets/icons/FiZoomIn.svg';
import FiZoomOut from '@/assets/icons/FiZoomOut.svg';
import FiMaximize from '@/assets/icons/FiMaximize.svg';
import { AIWorkflowBuilder } from './AIWorkflowBuilder';
import FiAiWorkflows from '@/assets/icons/FiAIWorkflows.svg';
import { GenericComponent } from '../CustomComponents';
import { FeatureFlagWrapper } from '@/components/FeatureFlagWrapper/FeatureFlagWrapper';
import { FEATURE_FLAG_KEYS } from '@/enterprise/hooks/useFeatureFlags';

export const NODE_TYPES = {
  generic_component: GenericComponent,
} satisfies NodeTypes;

const uid = new ShortUniqueId();

interface ControlButtonProps {
  icon: string;
  alt: string;
  onClick: () => void;
  title: string;
  disabled?: boolean;
  'data-testid'?: string;
}

const ControlButton = ({
  icon,
  alt,
  onClick,
  title,
  disabled = false,
  'data-testid': dataTestId,
}: ControlButtonProps) => (
  <Box
    data-testid={dataTestId}
    height='32px'
    width='32px'
    onClick={disabled ? undefined : onClick}
    title={title}
    display='flex'
    alignItems='center'
    justifyContent='center'
    cursor={disabled ? 'not-allowed' : 'pointer'}
    opacity={disabled ? 0.4 : 1}
    _hover={disabled ? {} : { bg: 'gray.50' }}
  >
    <Image src={icon} alt={alt} width='14px' height='14px' />
  </Box>
);

const AgentWorkflowCanvasInner = (): JSX.Element => {
  const agentId = useParams().id ?? '';
  const { screenToFlowPosition, zoomIn, zoomOut, fitView } = useReactFlow();
  const {
    nodes,
    edges,
    currentWorkflow,
    setNodes,
    setEdges,
    setWorkflow,
    setSelectedComponent,
    saveHistory,
    undo,
    redo,
    canUndo,
    canRedo,
    isPreviewMode,
  } = useAgentStore();
  const hasInitializedHistory = useRef(false);
  const [isAIBuilderOpen, setIsAIBuilderOpen] = useState(false);

  const handleDragEnd = (event: React.DragEvent<HTMLDivElement>, component: FlowComponent) => {
    // Don't allow adding components in preview mode
    if (isPreviewMode) return;

    const position = screenToFlowPosition({
      x: event.clientX,
      y: event.clientY,
    });
    const addComponent: FlowComponent = { ...component };
    addComponent.id = `${agentId}_${component.data.component}_${uid.randomUUID(5)}`;
    addComponent.position = position;
    addComponent.component_type = addComponent.data.component;
    addComponent.type = addComponent.component_category ?? 'generic_component';
    addComponent.configuration = addComponent.configuration ?? {};
    setNodes((nodes) => {
      const currentNodes = nodes.map((node) => ({ ...node, selected: false }));
      if (currentWorkflow) {
        const updatedWorkflow = { ...currentWorkflow };
        updatedWorkflow.workflow.components = [...currentNodes, { ...addComponent, position }];
        updatedWorkflow.workflow.status = 'draft';
        setWorkflow({ ...updatedWorkflow });
      }
      return [...currentNodes, { ...addComponent, position, selected: true }];
    });
    setSelectedComponent(addComponent);
    // Save history after adding a new component
    setTimeout(() => saveHistory(), 0);
  };

  // Keyboard shortcuts for undo/redo
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      const ctrlKey = event.metaKey || event.ctrlKey;

      if (ctrlKey && event.key === 'z' && !event.shiftKey) {
        event.preventDefault();
        if (canUndo()) {
          undo();
        }
      } else if (ctrlKey && (event.key === 'y' || (event.key === 'z' && event.shiftKey))) {
        event.preventDefault();
        if (canRedo()) {
          redo();
        }
      }
    },
    [undo, redo, canUndo, canRedo],
  );

  useEffect(() => {
    setSelectedComponent(null);
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);

  // Save initial state when workflow loads
  useEffect(() => {
    if (currentWorkflow && !hasInitializedHistory.current) {
      hasInitializedHistory.current = true;
      saveHistory();
    }
  }, [currentWorkflow, saveHistory]);

  const controls = [
    { icon: FiUndo, alt: 'Undo', onClick: undo, title: 'Undo (Ctrl+Z)', disabled: !canUndo() },
    { icon: FiRedo, alt: 'Redo', onClick: redo, title: 'Redo (Ctrl+Y)', disabled: !canRedo() },
    { icon: FiZoomIn, alt: 'Zoom In', onClick: () => zoomIn(), title: 'Zoom In' },
    { icon: FiZoomOut, alt: 'Zoom Out', onClick: () => zoomOut(), title: 'Zoom Out' },
    {
      icon: FiMaximize,
      alt: 'Fit View',
      onClick: () => fitView(),
      title: 'Fit View',
      'data-testid': 'workflow-canvas-fit-view',
    },
  ];

  return (
    <Flex flex='1' height='100%' overflow='hidden' position='relative'>
      {!isPreviewMode && (
        <Box position='relative'>
          <Sidebar handleDragEnd={handleDragEnd} />
        </Box>
      )}
      <ReactFlow
        data-testid='workflow-canvas'
        nodes={nodes}
        fitView
        edges={edges}
        nodeTypes={NODE_TYPES}
        onNodesChange={(changes) => {
          // In preview mode, only allow selection changes, not position/remove changes
          if (isPreviewMode) {
            const allowedChanges = changes.filter((change) => change.type === 'select');
            if (allowedChanges.length > 0) {
              setNodes((nds) => applyNodeChanges(allowedChanges, nds));
            }
            return;
          }

          let shouldSaveHistory = false;
          setNodes((nds) => {
            if (currentWorkflow) {
              const updateWorkflow = { ...currentWorkflow };
              let workflowMutated = false;
              for (const change of changes) {
                if (change.type === 'position' && !change.dragging) {
                  updateWorkflow.workflow.components = updateWorkflow.workflow.components.map(
                    (component) =>
                      component.id === change.id && change.position
                        ? {
                            ...component,
                            position: change.position,
                          }
                        : component,
                  );
                  workflowMutated = true;
                  shouldSaveHistory = true;
                }
              }
              if (workflowMutated) {
                setWorkflow(updateWorkflow);
              }
            }
            return applyNodeChanges(changes, nds);
          });
          // Save history after node position changes (when drag ends)
          if (shouldSaveHistory) {
            setTimeout(() => saveHistory(), 0);
          }
        }}
        onEdgesChange={(changes) => {
          // Don't allow edge changes in preview mode
          if (isPreviewMode) return;
          setEdges((eds) => applyEdgeChanges(changes, eds));
        }}
        onConnect={(connection) => {
          // Don't allow new connections in preview mode
          if (isPreviewMode) return;

          setSelectedComponent(null);
          if (currentWorkflow) {
            const updatedWorkflow = { ...currentWorkflow };
            const sourceHandle = getEdgeDataFromId(connection.sourceHandle ?? '');
            const targetHandle = getEdgeDataFromId(connection.targetHandle ?? '');
            if (sourceHandle && targetHandle) {
              const id = `xy-edge__${connection.source}-${connection.target}-${sourceHandle.field}-${targetHandle.field}`;
              const newConnection: Edge = { ...connection, id };
              const newEdge = {
                id,
                type: 'default',
                animated: true,
                source_component_id: connection.source,
                target_component_id: connection.target,
                source_handle: sourceHandle,
                target_handle: targetHandle,
              };
              const workflowEdges = updatedWorkflow.workflow.edges
                ? [...updatedWorkflow.workflow.edges, newEdge]
                : [newEdge];
              updatedWorkflow.workflow.edges = workflowEdges;
              updatedWorkflow.workflow.status = 'draft';
              setWorkflow(updatedWorkflow);
              setEdges((eds) => addEdge(newConnection, eds));
              // Save history after connecting edges
              setTimeout(() => saveHistory(), 0);
            }
          }
        }}
        onNodeClick={(_, node) => {
          setSelectedComponent(node);
        }}
        onPaneClick={() => {
          setSelectedComponent(null);
        }}
        onNodesDelete={(deletedNodes) => {
          // Don't allow node deletion in preview mode
          if (isPreviewMode) return;

          setSelectedComponent(null);
          if (currentWorkflow) {
            const deletedNodeIds = deletedNodes.map((node) => node.id);
            const updatedWorkflow = { ...currentWorkflow };
            updatedWorkflow.workflow.components = updatedWorkflow.workflow.components.filter(
              (node) => !deletedNodes.some((deletedNode) => deletedNode.id === node.id),
            );
            // Also remove edges that reference deleted nodes
            updatedWorkflow.workflow.edges = (updatedWorkflow.workflow.edges ?? []).filter(
              (edge) =>
                !deletedNodeIds.includes(edge.source_component_id) &&
                !deletedNodeIds.includes(edge.target_component_id),
            );
            // Update React Flow edges state
            setEdges((eds) =>
              eds.filter(
                (edge) =>
                  !deletedNodeIds.includes(edge.source) && !deletedNodeIds.includes(edge.target),
              ),
            );
            updatedWorkflow.workflow.status = 'draft';
            setWorkflow(updatedWorkflow);
            // Save history after deleting nodes
            setTimeout(() => saveHistory(), 0);
          }
        }}
        onEdgesDelete={(deletedEdges) => {
          // Don't allow edge deletion in preview mode
          if (isPreviewMode) return;

          setSelectedComponent(null);
          if (currentWorkflow) {
            const updatedWorkflow = { ...currentWorkflow };
            let updatedEdges = [...edges];
            updatedEdges = updatedEdges.filter((edge) => {
              const deletedEdge = deletedEdges.find((deletedEdge) => {
                return edge.id === deletedEdge.id;
              });
              if (deletedEdge) {
                updatedWorkflow.workflow.edges = updatedWorkflow.workflow.edges.filter((edge) => {
                  const id = constructEdgeId(edge);
                  return id !== deletedEdge.id;
                });
              }
              return deletedEdge === undefined;
            });
            setEdges(() => updatedEdges);
            updatedWorkflow.workflow.status = 'draft';
            setWorkflow(updatedWorkflow);
            // Save history after deleting edges
            setTimeout(() => saveHistory(), 0);
          }
        }}
        proOptions={{
          hideAttribution: true,
        }}
        multiSelectionKeyCode={null}
      >
        <Background
          color='#ccc'
          bgColor='#F9FAFB'
          variant={BackgroundVariant.Dots}
          size={2.5}
          gap={25}
        />
        <HStack
          position='absolute'
          bottom='20px'
          left='50%'
          transform='translateX(-50%)'
          zIndex={5}
          spacing={0}
          bg='white'
          borderRadius='8px'
          borderStyle='solid'
          borderColor='gray.400'
          borderWidth='1px'
          padding='4px'
        >
          <FeatureFlagWrapper flags={[FEATURE_FLAG_KEYS.promptWorkflow]}>
            <Button
              size='sm'
              variant='outline'
              fontWeight='bold'
              fontSize='xs'
              onClick={() => setIsAIBuilderOpen(!isAIBuilderOpen)}
              borderRadius='4px'
              color={'brand.400'}
              boxShadow='0px 0px 8px -2px #00249C40'
              paddingX='12px'
              border='1px solid'
              borderColor={isAIBuilderOpen ? 'brand.400' : 'gray.400'}
              bg={isAIBuilderOpen ? '#00249C1A' : 'gray.100'}
              isDisabled={isPreviewMode}
            >
              <Flex gap='8px' alignItems='center'>
                <Image src={FiAiWorkflows} width='14px' height='14px' />
                Build with AI
              </Flex>
            </Button>
          </FeatureFlagWrapper>
          {controls.map((control, index) => (
            <ControlButton key={index} {...control} />
          ))}
        </HStack>
      </ReactFlow>
      {!isPreviewMode && <Configbar />}
      <AIWorkflowBuilder isOpen={isAIBuilderOpen} onClose={() => setIsAIBuilderOpen(false)} />
    </Flex>
  );
};

const AgentWorkflowCanvas = (): JSX.Element => {
  return (
    <ReactFlowProvider>
      <AgentWorkflowCanvasInner />
    </ReactFlowProvider>
  );
};

export default AgentWorkflowCanvas;
