/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.apache.heron.spi.packing;

import org.apache.heron.common.basics.ByteAmount;

/**
 * Definition of Resources. Used to form packing structure output.
 */
public class Resource {
  private double cpu;
  private ByteAmount ram;
  private ByteAmount disk;
  private int gpu;

  public static final Resource EMPTY_RESOURCE
      = new Resource(0.0, ByteAmount.ZERO, ByteAmount.ZERO, 0);

  public Resource(double cpu, ByteAmount ram, ByteAmount disk, int gpu) {
    this.cpu = cpu;
    this.ram = ram;
    this.disk = disk;
    this.gpu = gpu;
  }

  @Override
  public boolean equals(Object obj) {
    if (obj instanceof Resource) {
      Resource r = (Resource) obj;
      return (this.getCpu() == r.getCpu())
          && (this.getRam().equals(r.getRam()))
          && (this.getDisk().equals(r.getDisk()));
    } else {
      return false;
    }
  }

  public double getCpu() {
    return cpu;
  }

  public ByteAmount getRam() {
    return ram;
  }

  public ByteAmount getDisk() {
    return disk;
  }

  public int getGpu() {
    return gpu;
  }

  public Resource cloneWithRam(ByteAmount newRam) {
    return new Resource(this.getCpu(), newRam, this.getDisk(), this.getGpu());
  }

  public Resource cloneWithCpu(double newCpu) {
    return new Resource(newCpu, this.getRam(), this.getDisk(), this.getGpu());
  }

  public Resource cloneWithDisk(ByteAmount newDisk) {
    return new Resource(this.getCpu(), this.getRam(), newDisk, this.getGpu());
  }

  public Resource cloneWithGpu(int newGpu) {
    return new Resource(this.getCpu(), this.getRam(), this.getDisk(), newGpu);
  }

  /**
   * Subtracts a given resource from the current resource. The results is never negative.
   */
  public Resource subtractAbsolute(Resource other) {
    double cpuDifference = this.getCpu() - other.getCpu();
    double extraCpu = Math.max(0, cpuDifference);
    ByteAmount ramDifference = this.getRam().minus(other.getRam());
    ByteAmount extraRam = ByteAmount.ZERO.max(ramDifference);
    ByteAmount diskDifference = this.getDisk().minus(other.getDisk());
    ByteAmount extraDisk = ByteAmount.ZERO.max(diskDifference);
    int gpuDifference = this.getGpu() - other.getGpu();
    int extraGpu = Math.max(0, gpuDifference);
    return new Resource(extraCpu, extraRam, extraDisk, extraGpu);
  }

   /**
   * Adds a given resource from the current resource.
   */
  public Resource plus(Resource other) {
    double totalCpu = this.getCpu() + other.getCpu();
    ByteAmount totalRam = this.getRam().plus(other.getRam());
    ByteAmount totalDisk = this.getDisk().plus(other.getDisk());
    int totalGpu = this.getGpu() + other.getGpu();
    return new Resource(totalCpu, totalRam, totalDisk, totalGpu);
  }

  /**
   * Divides a resource by another resource by dividing the CPU, memory and disk values of the resources.
   * It returns the maximum of the three results.
   */
  public double divideBy(Resource other) throws RuntimeException {
    if (other.getCpu() == 0 || other.getRam().isZero() || other.getDisk().isZero()) {
      throw new RuntimeException("Division by 0.");
    } else {
      double cpuFactor = Math.ceil(this.getCpu() / other.getCpu());
      double ramFactor = Math.ceil((double) this.getRam().asBytes() / other.getRam().asBytes());
      double diskFactor = Math.ceil((double) this.getDisk().asBytes() / other.getDisk().asBytes());
      return Math.max(cpuFactor, Math.max(ramFactor, diskFactor));
    }
  }

  @Override
  public int hashCode() {
    int result;
    long temp;
    temp = Double.doubleToLongBits(cpu);
    result = (int) (temp ^ (temp >>> 32));
    result = 31 * result + ram.hashCode();
    result = 31 * result + disk.hashCode();
    result = 31 * result + gpu;
    return result;
  }

  @Override
  public String toString() {
    return String.format("{cpu: %f, ram: %s, disk: %s, gpu: %s}",
        getCpu(), getRam(), getDisk(), getGpu());
  }
}
