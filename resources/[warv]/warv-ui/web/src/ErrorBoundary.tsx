import { Component, ErrorInfo, ReactNode } from "react";
import { useSelector } from ".";
import { reportUiError } from "./errorReporting";

interface Props {
  resetKey?: unknown;
  children: ReactNode;
}
interface State {
  hasError: boolean;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false };

  static getDerivedStateFromError(): State {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    reportUiError({
      kind: "react",
      message: error.message || String(error),
      stack: error.stack,
      componentStack: info.componentStack || undefined,
    });
  }

  componentDidUpdate(prev: Props) {
    if (this.state.hasError && prev.resetKey !== this.props.resetKey) {
      this.setState({ hasError: false });
    }
  }

  render() {
    return this.state.hasError ? null : this.props.children;
  }
}

const ErrorBoundaryHost = ({ children }: { children: ReactNode }) => {
  const screen = useSelector((s) => s.screen);
  return <ErrorBoundary resetKey={screen}>{children}</ErrorBoundary>;
};

export default ErrorBoundaryHost;
