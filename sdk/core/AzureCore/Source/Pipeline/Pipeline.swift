// --------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the ""Software""), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
// --------------------------------------------------------------------------

import Foundation

internal class Pipeline {
    private var policies: [PipelineStageProtocol]
    private let transport: HttpTransportable

    public init(transport: HttpTransportable, policies: [PipelineStageProtocol]) {
        self.transport = transport
        self.policies = policies
        var prevPolicy: PipelineStageProtocol?
        for policy in policies {
            if prevPolicy != nil {
                prevPolicy!.next = policy
            }
            prevPolicy = policy
        }
        var lastPolicy = self.policies.removeLast()
        lastPolicy.next = transport
        self.policies.append(lastPolicy)
    }

    public func run(request: PipelineRequest, completion: @escaping PipelineStageResultHandler) {
        if let firstPolicy = policies.first {
            firstPolicy.process(request: request) { result, httpResponse in
                switch result {
                case let .success(pipelineResponse):
                    completion(.success(pipelineResponse), httpResponse)
                case let .failure(error):
                    completion(.failure(error), httpResponse)
                }
            }
        }
    }
}